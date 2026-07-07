import 'package:injectable/injectable.dart';
import '../entities/daily_usage_summary.dart';
import '../i_daily_usage_repository.dart';
import '../i_network_stats_repository.dart';

/// Persists today's cumulative usage to Hive so the background service —
/// whose isolate has no platform-channel access — can evaluate spike and
/// threshold alerts against it.
@injectable
class SyncDailyUsageUseCase {
  final INetworkStatsRepository _networkRepo;
  final IDailyUsageRepository _dailyRepo;

  const SyncDailyUsageUseCase(this._networkRepo, this._dailyRepo);

  Future<void> call() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final apps = await _networkRepo.getAppUsage(start: todayStart, end: now);

      await _dailyRepo.saveDailySummary(DailyUsageSummary(
        date: todayStart,
        totalMobileBytes: apps.fold(0, (s, a) => s + a.totalMobileBytes),
        mobileForegroundBytes: apps.fold(0, (s, a) => s + a.mobileForegroundBytes),
        mobileBackgroundBytes: apps.fold(0, (s, a) => s + a.mobileBackgroundBytes),
        totalWifiBytes: apps.fold(0, (s, a) => s + a.totalWifiBytes),
      ));
    } catch (_) {
      // Best-effort housekeeping — never block the caller (e.g. dashboard load).
    }
  }
}
