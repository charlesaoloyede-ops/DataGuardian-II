import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/analytics/i_analytics_service.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/date_range_utils.dart';
import '../../domain/entities/app_usage_record.dart';
import '../../domain/i_network_stats_repository.dart';
import '../../domain/use_cases/get_app_usage_use_case.dart';

/// Which networks are currently toggled on by the user.
final visibleNetworksProvider =
    StateProvider<Set<NetworkView>>((ref) => {NetworkView.mobile, NetworkView.wifi});

final appUsageFilterProvider =
    StateProvider<DateRangeFilter>((ref) => DateRangeFilter.today());

/// Whether the next fetch should bypass cache (set to true by pull-to-refresh).
final _forceRefreshProvider = StateProvider<bool>((ref) => false);

final appUsageListProvider =
    FutureProvider.autoDispose<List<AppUsageRecord>>((ref) async {
  // Stay alive while the user navigates within the shell — prevents redundant
  // refetches when returning to this tab within the cache TTL window.
  final link = ref.keepAlive();

  final filter          = ref.watch(appUsageFilterProvider);
  final visibleNetworks = ref.watch(visibleNetworksProvider);
  final forceRefresh    = ref.watch(_forceRefreshProvider);

  final repo  = getIt<INetworkStatsRepository>();
  final apps  = await GetAppUsageUseCase(repo)(
    filter: filter,
    visibleNetworks: visibleNetworks,
    forceRefresh: forceRefresh,
  );

  // Reset force-refresh flag after use so next auto-refresh uses cache.
  if (forceRefresh) {
    Future.microtask(() => ref.read(_forceRefreshProvider.notifier).state = false);
  }

  getIt<IAnalyticsService>().logEvent(
    AnalyticsEvents.appUsageViewed,
    properties: {'filter': filter.preset.name, 'networks': visibleNetworks.map((v) => v.name).join('+')},
  );

  // Release keepAlive once data is loaded — the cached repo result handles
  // fast returns; we don't need to keep the provider in memory indefinitely.
  link.close();

  return apps;
});

/// Triggers a cache-bypassing refresh. Called by pull-to-refresh.
void invalidateAppUsage(WidgetRef ref) {
  ref.read(_forceRefreshProvider.notifier).state = true;
  ref.invalidate(appUsageListProvider);
}

/// Background-only usage — sorted descending by background bytes.
final backgroundUsageProvider =
    FutureProvider.autoDispose<List<AppUsageRecord>>((ref) async {
  final filter = ref.watch(appUsageFilterProvider);
  final repo   = getIt<INetworkStatsRepository>();
  final all    = await repo.getAppUsage(start: filter.start, end: filter.end);
  getIt<IAnalyticsService>().logEvent(AnalyticsEvents.backgroundUsageViewed);
  return (all
        ..sort((a, b) =>
            (b.mobileBackgroundBytes + b.wifiBackgroundBytes)
                .compareTo(a.mobileBackgroundBytes + a.wifiBackgroundBytes)))
      .where((r) => r.mobileBackgroundBytes + r.wifiBackgroundBytes > 0)
      .toList();
});
