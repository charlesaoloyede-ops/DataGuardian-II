import 'entities/daily_usage_summary.dart';

abstract class IDailyUsageRepository {
  Future<List<DailyUsageSummary>> getLast7Days();
  Future<List<DailyUsageSummary>> getLast30Days();
  Future<void> saveDailySummary(DailyUsageSummary summary);

  /// Returns completed daily summaries for the [days] preceding today.
  /// Used by spike detection to build a baseline average.
  Future<List<DailyUsageSummary>> getBaselineDays(int days);
}
