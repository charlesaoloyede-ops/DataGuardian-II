import 'package:injectable/injectable.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/storage/hive_service.dart';
import '../domain/entities/daily_usage_summary.dart';
import '../domain/i_daily_usage_repository.dart';

@LazySingleton(as: IDailyUsageRepository)
class DailyUsageRepositoryImpl implements IDailyUsageRepository {
  final HiveService _hive;
  DailyUsageRepositoryImpl(this._hive);

  /// Key format: 'yyyy-MM-dd' — one record per calendar day.
  static String _keyFor(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  Future<List<DailyUsageSummary>> getLast7Days() => _getLastNDays(7);

  @override
  Future<List<DailyUsageSummary>> getLast30Days() => _getLastNDays(30);

  @override
  Future<void> saveDailySummary(DailyUsageSummary summary) async {
    final key = _keyFor(summary.date);
    await _hive.dailyUsageBox.put(key, summary);
  }

  // ── new method used by CheckSpikeUseCase ──────────────────────────────────

  /// Returns summaries for [days] ending yesterday (exclusive of today so
  /// in-progress data does not skew the baseline).
  @override
  Future<List<DailyUsageSummary>> getBaselineDays(int days) async {
    final today = DateTime.now();
    final cutoff = DateTime(today.year, today.month, today.day); // midnight today
    return _getRange(days, cutoff);
  }

  // ── private helpers ──────────────────────────────────────────────────────

  Future<List<DailyUsageSummary>> _getLastNDays(int n) async {
    final now = DateTime.now();
    final cutoff = DateTime(now.year, now.month, now.day + 1); // inclusive today
    return _getRange(n, cutoff);
  }

  Future<List<DailyUsageSummary>> _getRange(int n, DateTime cutoff) async {
    final earliest = cutoff.subtract(Duration(days: n));
    final box = _hive.dailyUsageBox;
    final results = box.values
        .where((s) => s.date.isAfter(earliest) && s.date.isBefore(cutoff))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return results;
  }

  /// Purges records older than [AppConstants.maxDateRangeMonths] months.
  Future<void> purgeOldRecords() async {
    final cutoff = DateTime.now()
        .subtract(const Duration(days: AppConstants.maxDateRangeMonths * 31));
    final box = _hive.dailyUsageBox;
    final staleKeys = box.keys.cast<String>().where((k) {
      final parts = k.split('-');
      if (parts.length != 3) return false;
      final d = DateTime.tryParse(k);
      return d != null && d.isBefore(cutoff);
    }).toList();
    await box.deleteAll(staleKeys);
  }
}
