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
    Set<NetworkView> visibleNetworks = const {NetworkView.mobile, NetworkView.wifi},
    bool forceRefresh = false,
  }) async {
    final records = await _repository.getAppUsage(
      start: filter.start,
      end: filter.end,
      forceRefresh: forceRefresh,
    );

    if (visibleNetworks.isEmpty) return [];

    // Filter: keep apps with usage in at least one visible network
    final filtered = records.where((r) {
      if (visibleNetworks.contains(NetworkView.mobile) && r.totalMobileBytes > 0) return true;
      if (visibleNetworks.contains(NetworkView.wifi) && r.totalWifiBytes > 0) return true;
      return false;
    }).toList();

    // Sort personal-first, then descending by relevant bytes
    filtered.sort((a, b) {
      if (a.isSystemApp != b.isSystemApp) return a.isSystemApp ? 1 : -1;
      final aBytes = _sortBytes(a, visibleNetworks);
      final bBytes = _sortBytes(b, visibleNetworks);
      return bBytes.compareTo(aBytes);
    });

    return filtered;
  }

  int _sortBytes(AppUsageRecord r, Set<NetworkView> visible) {
    if (visible.length == 1) {
      return visible.contains(NetworkView.mobile) ? r.totalMobileBytes : r.totalWifiBytes;
    }
    return r.totalMobileBytes + r.totalWifiBytes; // both visible → sort by total
  }
}

enum NetworkView { mobile, wifi }
