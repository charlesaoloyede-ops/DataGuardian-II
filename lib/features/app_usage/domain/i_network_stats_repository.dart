import 'entities/app_usage_record.dart';

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

  Future<bool> isUsageAccessGranted();
}
