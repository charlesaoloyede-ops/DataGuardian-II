import 'entities/daily_usage_summary.dart';

abstract class IDailyUsageRepository {
  Future<List<DailyUsageSummary>> getLast7Days();
  Future<List<DailyUsageSummary>> getLast30Days();
  Future<void> saveDailySummary(DailyUsageSummary summary);
}
