import 'entities/app_usage_record.dart';
import 'entities/daily_usage_summary.dart';

abstract class INetworkStatsRepository {
  /// Returns all apps with non-zero usage in [start..end], excluding system
  /// apps with zero consumption. Grouped: personal apps first, then system.
  Future<List<AppUsageRecord>> getAppUsage({
    required DateTime start,
    required DateTime end,
    bool forceRefresh = false,
  });

  Future<int> getTotalMobileUsage({
    required DateTime start,
    required DateTime end,
  });

  /// Device-level mobile + Wi-Fi totals for each calendar day in [start..end]
  /// (oldest first, one entry per day, zero when a day has no usage). Backs the
  /// dashboard 7-day chart from live NetworkStatsManager data.
  Future<List<DailyUsageSummary>> getDailyTotals({
    required DateTime start,
    required DateTime end,
  });

  Future<bool> isUsageAccessGranted();
}
