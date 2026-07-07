import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/analytics/i_analytics_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/di/injection.dart';
import '../../features/alerts/domain/entities/alert_record.dart';
import '../../features/alerts/domain/entities/alert_type.dart';
import '../../features/alerts/domain/i_alert_repository.dart';
import '../../features/alerts/domain/use_cases/check_spike_use_case.dart';
import '../../features/alerts/domain/use_cases/save_alert_use_case.dart';
import '../../features/app_usage/domain/i_daily_usage_repository.dart';
import '../../services/storage/hive_service.dart';
import '../../services/storage/shared_prefs_service.dart';

/// Background service entry point. Runs in a separate Dart isolate.
///
/// Platform channels for NetworkStats / UsageStats are only registered with
/// the main FlutterEngine (via MainActivity), so all checks here use
/// Hive-persisted daily summaries (written by the foreground app via
/// [SyncDailyUsageUseCase] whenever the dashboard is viewed) rather than
/// live network data.
@pragma('vm:entry-point')
Future<void> onServiceStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  await HiveService.init();
  await configureDependencies();

  final notifPlugin = FlutterLocalNotificationsPlugin();
  await notifPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((_) => service.setAsForegroundService());
    service.on('setAsBackground').listen((_) => service.setAsBackgroundService());
  }
  service.on('stopService').listen((_) => service.stopSelf());

  await _poll(service, notifPlugin);
  Timer.periodic(
    const Duration(minutes: AppConstants.backgroundPollIntervalMinutes),
    (_) => _poll(service, notifPlugin),
  );
}

Future<void> _poll(
  ServiceInstance service,
  FlutterLocalNotificationsPlugin notifPlugin,
) async {
  try {
    final prefs = getIt<SharedPrefsService>();
    if (!prefs.getPreferences().notificationsEnabled) return;

    final dailyRepo = getIt<IDailyUsageRepository>();
    final saveAlert = getIt<SaveAlertUseCase>();
    final now       = DateTime.now();
    final today     = DateTime(now.year, now.month, now.day);

    // Use today's Hive summary (written by the foreground app; see SyncDailyUsageUseCase).
    final last7 = await dailyRepo.getLast7Days();
    final todaySummaries = last7.where((d) =>
        d.date.year == today.year &&
        d.date.month == today.month &&
        d.date.day == today.day);

    if (todaySummaries.isEmpty) {
      _updateForegroundNotif(service, 'Waiting for usage data...');
      return;
    }

    final todaySummary = todaySummaries.first;

    // Recent alerts — used to avoid re-firing the same alert on every 15-min poll.
    final recentAlerts = await getIt<IAlertRepository>().getAlerts();
    bool firedToday(String idPrefix) => recentAlerts.any((a) =>
        a.id.startsWith(idPrefix) &&
        a.triggeredAt.year == today.year &&
        a.triggeredAt.month == today.month &&
        a.triggeredAt.day == today.day);

    // Spike detection (Hive-based; no platform channel required).
    final spikeUseCase = await getIt.getAsync<CheckSpikeUseCase>();
    final spikeResult  = await spikeUseCase(todaySummary);

    if (spikeResult != null && spikeResult.isSpike && !firedToday('spike_')) {
      final msg = 'Data spike detected: ${_fmtMb(spikeResult.todayBytes)} today '
          '(${spikeResult.multiplierUsed.toStringAsFixed(1)}× your 7-day average)';
      final alert = AlertRecord(
        id: 'spike_${now.millisecondsSinceEpoch}',
        type: AlertType.spike,
        triggeredAt: now,
        message: msg,
      );
      await saveAlert(alert);
      getIt<IAnalyticsService>().logEvent(
        AnalyticsEvents.spikeAlertFired,
        properties: {
          'todayMb': (spikeResult.todayBytes / 1000000).toStringAsFixed(1),
          'multiplier': spikeResult.multiplierUsed.toStringAsFixed(2),
        },
      );
      await notifPlugin.show(2001, 'Data Spike Detected', msg, _alertNotifDetails());
    }

    // Daily mobile threshold.
    final dailyLimit = prefs.getPreferences().dailyThresholdBytes;
    if (dailyLimit != null &&
        dailyLimit > 0 &&
        todaySummary.totalMobileBytes > dailyLimit &&
        !firedToday('daily_threshold_')) {
      final msg = 'Daily mobile data limit reached: '
          '${_fmtMb(todaySummary.totalMobileBytes)} of ${_fmtMb(dailyLimit)}';
      final alert = AlertRecord(
        id: 'daily_threshold_${now.millisecondsSinceEpoch}',
        type: AlertType.threshold,
        triggeredAt: now,
        message: msg,
      );
      await saveAlert(alert);
      getIt<IAnalyticsService>().logEvent(
        AnalyticsEvents.thresholdAlertFired,
        properties: {'period': 'daily', 'limitMb': (dailyLimit / 1000000).toStringAsFixed(0)},
      );
      await notifPlugin.show(2002, 'Daily Data Limit Reached', msg, _alertNotifDetails());
    }

    // Weekly mobile threshold.
    final weeklyLimit = prefs.getPreferences().weeklyThresholdBytes;
    if (weeklyLimit != null && weeklyLimit > 0 && !firedToday('weekly_threshold_')) {
      final weeklyTotal = last7.fold<int>(0, (sum, d) => sum + d.totalMobileBytes);
      if (weeklyTotal > weeklyLimit) {
        final msg = 'Weekly mobile data limit reached: '
            '${_fmtMb(weeklyTotal)} of ${_fmtMb(weeklyLimit)}';
        final alert = AlertRecord(
          id: 'weekly_threshold_${now.millisecondsSinceEpoch}',
          type: AlertType.threshold,
          triggeredAt: now,
          message: msg,
        );
        await saveAlert(alert);
        getIt<IAnalyticsService>().logEvent(
          AnalyticsEvents.thresholdAlertFired,
          properties: {'period': 'weekly', 'limitMb': (weeklyLimit / 1000000).toStringAsFixed(0)},
        );
        await notifPlugin.show(2004, 'Weekly Data Limit Reached', msg, _alertNotifDetails());
      }
    }

    // Check background-data threshold against today's Hive summary.
    final bgBytes = todaySummary.mobileBackgroundBytes;
    final bgLimit = prefs.getPreferences().backgroundThresholdBytes;
    if (bgLimit != null &&
        bgLimit > 0 &&
        bgBytes > bgLimit &&
        !firedToday('bg_threshold_')) {
      final msg = 'Background data limit exceeded: ${_fmtMb(bgBytes)} of ${_fmtMb(bgLimit)}';
      final alert = AlertRecord(
        id: 'bg_threshold_${now.millisecondsSinceEpoch}',
        type: AlertType.background,
        triggeredAt: now,
        message: msg,
      );
      await saveAlert(alert);
      getIt<IAnalyticsService>().logEvent(
        AnalyticsEvents.thresholdAlertFired,
        properties: {'period': 'background', 'limitMb': (bgLimit / 1000000).toStringAsFixed(0)},
      );
      await notifPlugin.show(2003, 'Background Data Alert', msg, _alertNotifDetails());
    }

    _updateForegroundNotif(
      service,
      'Today: ${_fmtMb(todaySummary.totalMobileBytes)} mobile · '
      '${_fmtMb(todaySummary.totalWifiBytes)} Wi-Fi',
    );
  } catch (_) {
    // Never crash the background service.
  }
}

void _updateForegroundNotif(ServiceInstance service, String content) {
  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: 'Data Guardian',
      content: content,
    );
  }
}

NotificationDetails _alertNotifDetails() => const NotificationDetails(
      android: AndroidNotificationDetails(
        AppConstants.alertChannelId,
        AppConstants.alertChannelName,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );

String _fmtMb(int bytes) {
  final mb = bytes / 1000000;
  if (mb >= 1000) return '${(mb / 1000).toStringAsFixed(1)} GB';
  return '${mb.toStringAsFixed(0)} MB';
}
