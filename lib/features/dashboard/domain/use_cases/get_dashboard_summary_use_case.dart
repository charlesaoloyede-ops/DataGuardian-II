import 'package:injectable/injectable.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/date_range_utils.dart';
import '../../../../services/storage/shared_prefs_service.dart';
import '../../../app_usage/domain/entities/app_usage_record.dart';
import '../../../app_usage/domain/i_network_stats_repository.dart';
import '../entities/dashboard_summary.dart';

@injectable
class GetDashboardSummaryUseCase {
  final INetworkStatsRepository _networkRepo;
  final SharedPrefsService _prefs;

  const GetDashboardSummaryUseCase(
    this._networkRepo,
    this._prefs,
  );

  Future<DashboardSummary> call() async {
    final prefs = _prefs.getPreferences();

    final billingFilter = DateRangeFilter.billingCycle(
      prefs.billingCycleStartDay > 0 ? prefs.billingCycleStartDay : null,
    );
    // 7-day chart window: the last 7 calendar days ending today.
    final sevenDayFilter = DateRangeFilter.last7Days();

    // Fire all queries concurrently.
    final billingTotalFuture = _networkRepo.getTotalMobileUsage(
        start: billingFilter.start, end: billingFilter.end);
    final allAppsFuture = _networkRepo.getAppUsage(
        start: billingFilter.start, end: billingFilter.end);
    // Read the 7-day series live (same NetworkStatsManager source as the App
    // Usage screen) so the chart stays consistent with the rest of the app
    // instead of relying on sparse, opportunistically-written Hive snapshots.
    final last7DaysFuture = _networkRepo.getDailyTotals(
        start: sevenDayFilter.start, end: sevenDayFilter.end);

    final billingTotal = await billingTotalFuture;
    final allApps      = await allAppsFuture;
    final last7Days    = await last7DaysFuture;

    // Top apps — personal-first, then descending by mobile bytes.
    final sorted = List<AppUsageRecord>.from(allApps)
      ..sort((a, b) {
        if (a.isSystemApp != b.isSystemApp) return a.isSystemApp ? 1 : -1;
        return b.totalMobileBytes.compareTo(a.totalMobileBytes);
      });
    final topApps = sorted.take(AppConstants.dashboardTopAppsCount).toList();

    return DashboardSummary(
      billingCycleMobileBytes: billingTotal,
      billingCycleMobileLimit: null, // monthly limit not yet in UserPreferences
      last7Days: last7Days,
      topApps: topApps,
      allApps: allApps,
      billingCycleStart: billingFilter.start,
      hasAnomaly: _isAnomalous(last7Days, prefs.spikeThresholdMultiplier),
    );
  }

  /// Flags an anomaly when today's mobile usage exceeds [multiplier]× the
  /// average of the preceding days that had any usage.
  bool _isAnomalous(List<dynamic> days, double multiplier) {
    if (days.length < 2) return false;
    final today = days.last.totalMobileBytes as int;
    final prior = days.sublist(0, days.length - 1);
    final withUsage = prior.where((d) => (d.totalMobileBytes as int) > 0).toList();
    if (withUsage.length < AppConstants.minBaselineDays) return false;
    final avg = withUsage.fold<int>(0, (s, d) => s + (d.totalMobileBytes as int)) /
        withUsage.length;
    return avg > 0 && today > avg * multiplier;
  }
}
