import 'package:injectable/injectable.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../services/storage/shared_prefs_service.dart';
import '../../../app_usage/domain/entities/daily_usage_summary.dart';
import '../../../app_usage/domain/i_daily_usage_repository.dart';

/// Result returned by [CheckSpikeUseCase].
class SpikeCheckResult {
  const SpikeCheckResult({
    required this.isSpike,
    required this.todayBytes,
    required this.baselineAvgBytes,
    required this.multiplierUsed,
  });

  final bool isSpike;
  final int todayBytes;

  /// Rolling average of [AppConstants.baselineLookbackDays] preceding days.
  final double baselineAvgBytes;
  final double multiplierUsed;

  /// Returns null when there are not enough baseline days to make a call.
  static SpikeCheckResult? noBaseline() => null;
}

/// Detects whether today's mobile usage is anomalously high.
///
/// Algorithm:
///   1. Load the previous [AppConstants.baselineLookbackDays] completed days.
///   2. Require at least [AppConstants.minBaselineDays] to proceed.
///   3. Compute average. Flag spike when today > average × spikeMultiplier.
@injectable
class CheckSpikeUseCase {
  final IDailyUsageRepository _dailyRepo;
  final SharedPrefsService _prefs;

  const CheckSpikeUseCase(this._dailyRepo, this._prefs);

  /// [todaySummary] — the in-progress or completed summary for today.
  /// Returns null when there is insufficient baseline history.
  Future<SpikeCheckResult?> call(DailyUsageSummary todaySummary) async {
    final baseline = await _dailyRepo.getBaselineDays(
      AppConstants.baselineLookbackDays,
    );

    if (baseline.length < AppConstants.minBaselineDays) return null;

    final prefs = _prefs.getPreferences();
    final multiplier = prefs.spikeThresholdMultiplier;

    final totalBaseline =
        baseline.fold<int>(0, (sum, d) => sum + d.totalMobileBytes);
    final avgBaseline = totalBaseline / baseline.length;

    final isSpike = avgBaseline > 0 &&
        todaySummary.totalMobileBytes > avgBaseline * multiplier;

    return SpikeCheckResult(
      isSpike: isSpike,
      todayBytes: todaySummary.totalMobileBytes,
      baselineAvgBytes: avgBaseline,
      multiplierUsed: multiplier,
    );
  }
}
