import 'package:injectable/injectable.dart';
import '../../../../core/utils/date_range_utils.dart';
import '../entities/app_usage_record.dart';
import '../i_network_stats_repository.dart';

/// Returns non-zero-usage apps for [filter], grouped personal-first.
/// Accepts an optional [networkView] to sort by mobile or Wi-Fi bytes.
@injectable
class GetAppUsageUseCase {
  final INetworkStatsRepository _repository;
  const GetAppUsageUseCase(this._repository);

  Future<List<AppUsageRecord>> call({
    required DateRangeFilter filter,
    NetworkView networkView = NetworkView.mobile,
  }) async {
    final records = await _repository.getAppUsage(
      start: filter.start,
      end: filter.end,
    );

    // Filter out zero-consumption apps
    final nonZero = records.where((r) {
      return switch (networkView) {
        NetworkView.mobile => r.totalMobileBytes > 0,
        NetworkView.wifi => r.totalWifiBytes > 0,
      };
    }).toList();

    // Sort descending by selected metric, personal apps first
    nonZero.sort((a, b) {
      if (a.isSystemApp != b.isSystemApp) {
        return a.isSystemApp ? 1 : -1; // personal first
      }
      final aBytes = networkView == NetworkView.mobile
          ? a.totalMobileBytes
          : a.totalWifiBytes;
      final bBytes = networkView == NetworkView.mobile
          ? b.totalMobileBytes
          : b.totalWifiBytes;
      return bBytes.compareTo(aBytes);
    });

    return nonZero;
  }
}

enum NetworkView { mobile, wifi }
