import 'package:injectable/injectable.dart';
import '../../../../core/utils/date_range_utils.dart';
import '../../../../services/storage/shared_prefs_service.dart';
import '../../../app_usage/domain/i_network_stats_repository.dart';

enum ThresholdType { daily, weekly, background }

class ThresholdCheckResult {
  const ThresholdCheckResult({
    required this.type,
    required this.isExceeded,
    required this.usageBytes,
    required this.limitBytes,
  });

  final ThresholdType type;
  final bool isExceeded;
  final int usageBytes;
  final int limitBytes;

  double get fractionUsed =>
      limitBytes > 0 ? (usageBytes / limitBytes).clamp(0.0, 2.0) : 0;
}

/// Checks daily and weekly mobile data thresholds from [UserPreferences].
///
/// Returns a list of all *exceeded* thresholds. Empty list means all clear.
@injectable
class CheckThresholdUseCase {
  final INetworkStatsRepository _networkRepo;
  final SharedPrefsService _prefs;

  const CheckThresholdUseCase(this._networkRepo, this._prefs);

  Future<List<ThresholdCheckResult>> call() async {
    final prefs = _prefs.getPreferences();
    final exceeded = <ThresholdCheckResult>[];

    final checks = <(ThresholdType, int?, DateRangeFilter)>[
      (ThresholdType.daily, prefs.dailyThresholdBytes, DateRangeFilter.today()),
      (
        ThresholdType.weekly,
        prefs.weeklyThresholdBytes,
        DateRangeFilter.last7Days()
      ),
    ];

    await Future.wait([
      for (final (type, limit, filter) in checks)
        if (limit != null && limit > 0)
          _networkRepo
              .getTotalMobileUsage(start: filter.start, end: filter.end)
              .then((usage) {
            if (usage > limit) {
              exceeded.add(ThresholdCheckResult(
                type: type,
                isExceeded: true,
                usageBytes: usage,
                limitBytes: limit,
              ));
            }
          }),
    ]);

    return exceeded;
  }
}
