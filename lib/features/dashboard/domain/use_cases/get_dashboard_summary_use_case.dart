import 'package:injectable/injectable.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/date_range_utils.dart';
import '../../../../services/storage/shared_prefs_service.dart';
import '../../../app_usage/domain/entities/app_usage_record.dart';
import '../../../app_usage/domain/i_daily_usage_repository.dart';
import '../../../app_usage/domain/i_network_stats_repository.dart';
import '../../../app_usage/domain/use_cases/sync_daily_usage_use_case.dart';
import '../entities/dashboard_summary.dart';

@injectable
class GetDashboardSummaryUseCase {
  final INetworkStatsRepository _networkRepo;
  final IDailyUsageRepository _dailyRepo;
  final SharedPrefsService _prefs;
  final SyncDailyUsageUseCase _syncDailyUsage;

  const GetDashboardSummaryUseCase(
    this._networkRepo,
    this._dailyRepo,
    this._prefs,
    this._syncDailyUsage,
  );

  Future<DashboardSummary> call() async {
    final prefs = _prefs.getPreferences();

    final billingFilter = DateRangeFilter.billingCycle(
      prefs.billingCycleStartDay > 0 ? prefs.billingCycleStartDay : null,
    );

    // Fire all queries concurrently. Syncing today's usage into Hive lets the
    // background service (no platform-channel access in its isolate) evaluate
    // spike/threshold alerts against fresh data.
    final billingTotalFuture = _networkRepo.getTotalMobileUsage(
        start: billingFilter.start, end: billingFilter.end);
    final allAppsFuture = _networkRepo.getAppUsage(
        start: billingFilter.start, end: billingFilter.end);
    final last7DaysFuture = _dailyRepo.getLast7Days();
    final syncFuture = _syncDailyUsage();

    final billingTotal = await billingTotalFuture;
    final allApps      = await allAppsFuture;
    final last7Days    = await last7DaysFuture;
    await syncFuture;

    // Top apps — personal-first, then descending by mobile bytes.
    final sorted = List<AppUsageRecord>.from(allApps)
      ..sort((a, b) {
        if (a.isSystemApp != b.isSystemApp) return a.isSystemApp ? 1 : -1;
        return b.totalMobileBytes.compareTo(a.totalMobileBytes);
      });
    final topApps = sorted.take(AppConstants.dashboardTopAppsCount).toList();

    final hasAnomaly = last7Days.any((d) => d.isAnomaly);

    return DashboardSummary(
      billingCycleMobileBytes: billingTotal,
      billingCycleMobileLimit: null, // monthly limit not yet in UserPreferences
      last7Days: last7Days,
      topApps: topApps,
      allApps: allApps,
      billingCycleStart: billingFilter.start,
      hasAnomaly: hasAnomaly,
    );
  }
}
