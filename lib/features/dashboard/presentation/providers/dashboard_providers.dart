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
  for (final entry in pending) {
    final typeName = entry['type'] as String? ?? 'threshold';
    final type = AlertType.values.firstWhere(
      (t) => t.name == typeName,
      orElse: () => AlertType.threshold,
    );
    final triggeredAt = DateTime.fromMillisecondsSinceEpoch(
      (entry['triggeredAtMs'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
    );
    await saveAlert(AlertRecord(
      id: 'native_${type.name}_${triggeredAt.millisecondsSinceEpoch}',
      type: type,
      triggeredAt: triggeredAt,
      message: entry['message'] as String? ?? 'Data alert',
    ));
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
