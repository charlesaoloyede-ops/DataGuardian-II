import '../../../app_usage/domain/entities/app_usage_record.dart';
import '../../../app_usage/domain/entities/daily_usage_summary.dart';

/// Aggregated data consumed by the Dashboard screen.
class DashboardSummary {
  const DashboardSummary({
    required this.billingCycleMobileBytes,
    required this.billingCycleMobileLimit,
    required this.last7Days,
    required this.topApps,
    required this.allApps,
    required this.billingCycleStart,
    required this.hasAnomaly,
  });

  /// Total mobile bytes used in the current billing cycle.
  final int billingCycleMobileBytes;

  /// User-configured monthly limit in bytes, or null if unset.
  final int? billingCycleMobileLimit;

  /// Daily summaries for the past 7 calendar days (oldest first).
  final List<DailyUsageSummary> last7Days;

  /// Top [AppConstants.dashboardTopAppsCount] apps by total mobile bytes.
  final List<AppUsageRecord> topApps;

  /// All apps with usage in the current billing cycle — used for per-app
  /// budget threshold checks (topApps is truncated).
  final List<AppUsageRecord> allApps;

  /// Start date of the current billing cycle (used to key budget-alert state).
  final DateTime billingCycleStart;

  /// True if any day in [last7Days] was flagged as anomalous.
  final bool hasAnomaly;

  double get billingCycleUsageFraction {
    if (billingCycleMobileLimit == null || billingCycleMobileLimit! <= 0) {
      return 0;
    }
    return (billingCycleMobileBytes / billingCycleMobileLimit!).clamp(0.0, 1.0);
  }
}
