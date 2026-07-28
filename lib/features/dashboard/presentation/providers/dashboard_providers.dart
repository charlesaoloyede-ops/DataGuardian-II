import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/analytics/i_analytics_service.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/int_extensions.dart';
import '../../../../features/alerts/domain/entities/alert_record.dart';
import '../../../../features/alerts/domain/entities/alert_type.dart';
import '../../../../features/alerts/domain/use_cases/check_budget_use_case.dart';
import '../../../../features/alerts/domain/use_cases/save_alert_use_case.dart';
import '../../../../features/app_usage/domain/i_network_stats_repository.dart';
import '../../../../services/notification/i_notification_service.dart';
import '../../../../services/storage/shared_prefs_service.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/use_cases/get_dashboard_summary_use_case.dart';

final dashboardSummaryProvider =
    FutureProvider.autoDispose<DashboardSummary>((ref) async {
  final prefs   = await getIt.getAsync<SharedPrefsService>();
  final network = getIt<INetworkStatsRepository>();
  final summary = await GetDashboardSummaryUseCase(network, prefs)();
  getIt<IAnalyticsService>().logEvent(AnalyticsEvents.dashboardViewed);

  await _drainNativeAlerts(prefs);
  await _checkBudgetAlerts(summary);

  return summary;
});

/// Persists alerts the native background monitor fired while the app was closed
/// into the Alerts Center (the monitor can post system notifications but can't
/// write Hive). Notifications were already shown natively, so this only records
/// history — it does not re-notify.
Future<void> _drainNativeAlerts(SharedPrefsService prefs) async {
  final pending = await prefs.drainPendingNativeAlerts();
  if (pending.isEmpty) return;

  final saveAlert = getIt<SaveAlertUseCase>();
  for (var i = 0; i < pending.length; i++) {
    final entry = pending[i];
    final typeName = entry['type'] as String? ?? 'threshold';
    final type = _alertTypeFromNative(typeName);
    final triggeredAt = DateTime.fromMillisecondsSinceEpoch(
      (entry['triggeredAtMs'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
    );
    await saveAlert(AlertRecord(
      // Include the raw native type and the loop index so multiple alerts from
      // one worker run (which all share the same triggeredAt) get distinct ids.
      id: 'native_${typeName}_${triggeredAt.millisecondsSinceEpoch}_$i',
      type: type,
      triggeredAt: triggeredAt,
      message: entry['message'] as String? ?? 'Data alert',
    ));
  }
}

/// Maps the native worker's alert type strings to [AlertType]. Both bundle
/// alerts share the [AlertType.bundle] category; the message text distinguishes
/// the exhaustion warning from the top-up nudge.
AlertType _alertTypeFromNative(String typeName) {
  switch (typeName) {
    case 'spike':
      return AlertType.spike;
    case 'background':
      return AlertType.background;
    case 'bundle_risk':
    case 'bundle_topup':
      return AlertType.bundle;
    default:
      return AlertType.threshold;
  }
}

/// Notifies the user when a per-app data budget crosses 70/80/90/100%.
/// Runs whenever the dashboard is viewed — per-app usage requires a live
/// platform-channel call, which is only available in the foreground.
Future<void> _checkBudgetAlerts(DashboardSummary summary) async {
  final checkBudget = await getIt.getAsync<CheckBudgetUseCase>();
  final breaches = await checkBudget(summary.allApps, summary.billingCycleStart);

  for (final breach in breaches) {
    final message = '${breach.appName} reached ${breach.thresholdPercent}% of its '
        'data budget (${breach.usageBytes.formattedBytes} of ${breach.budgetBytes.formattedBytes})';
    final alert = AlertRecord(
      id: 'budget_${breach.packageName}_${DateTime.now().millisecondsSinceEpoch}',
      type: AlertType.budget,
      triggeredAt: DateTime.now(),
      message: message,
    );
    await getIt<SaveAlertUseCase>().call(alert);
    getIt<IAnalyticsService>().logEvent(
      AnalyticsEvents.budgetAlertFired,
      properties: {
        'package': breach.packageName,
        'thresholdPercent': breach.thresholdPercent,
      },
    );
    await getIt<INotificationService>().showBudgetAlert(
      title: 'Data Budget Alert',
      body: message,
    );
  }
}
