import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import '../domain/entities/app_usage_record.dart';
import '../domain/i_network_stats_repository.dart';
import '../../../core/analytics/i_analytics_service.dart';
import '../../../core/constants/app_constants.dart';

/// Bridges Dart to [NetworkStatsChannel.kt] (network bytes) and
/// [UsageStatsChannel.kt] (foreground screen-on time).
///
/// [getAppUsage] calls both channels in parallel and merges the results so
/// each [AppUsageRecord] carries both network bytes and foreground screen time.
@LazySingleton(as: INetworkStatsRepository)
class AppUsageRepositoryImpl implements INetworkStatsRepository {
  static const _networkChannel = MethodChannel(AppConstants.networkStatsChannel);
  static const _usageChannel   = MethodChannel(AppConstants.usageStatsChannel);

  final IAnalyticsService _analytics;
  const AppUsageRepositoryImpl(this._analytics);

  // ── INetworkStatsRepository ──────────────────────────────────────────────

  @override
  Future<bool> isUsageAccessGranted() async =>
      await _usageChannel.invokeMethod<bool>('isUsageAccessGranted') ?? false;

  @override
  Future<List<AppUsageRecord>> getAppUsage({
    required DateTime start,
    required DateTime end,
  }) async {
    final args = {
      'startMs': start.millisecondsSinceEpoch,
      'endMs':   end.millisecondsSinceEpoch,
    };

    try {
      // Fire both channels in parallel; a foreground-time failure is non-fatal.
      final networkFuture  = _networkChannel.invokeMethod<List<dynamic>>('getNetworkStats', args);
      final foregroundFuture = _fetchForegroundTime(args);

      final rawNetwork = await networkFuture;
      final foreground = await foregroundFuture;

      if (rawNetwork == null) return [];

      return rawNetwork
          .cast<Map<dynamic, dynamic>>()
          .map((m) => _recordFromMap(m, foregroundTime: foreground))
          .toList();
    } on PlatformException catch (e) {
      if (e.code == 'USAGE_ACCESS_REQUIRED') rethrow;
      // OEM restriction — log and surface an empty list (repo caller shows banner).
      await _analytics.logEvent(
        AnalyticsEvents.networkStatsRestricted,
        properties: {'error': e.message ?? 'unknown'},
      );
      return [];
    }
  }

  @override
  Future<int> getTotalMobileUsage({
    required DateTime start,
    required DateTime end,
  }) async {
    final apps = await getAppUsage(start: start, end: end);
    return apps.fold<int>(0, (sum, a) => sum + a.totalMobileBytes);
  }

  // ── private helpers ──────────────────────────────────────────────────────

  /// Returns { packageName → foregroundTimeMs } from UsageStatsManager.
  /// Returns an empty map on OEM restriction — network bytes are still shown.
  Future<Map<String, int>> _fetchForegroundTime(Map<String, int> args) async {
    try {
      final raw = await _usageChannel.invokeMethod<List<dynamic>>('getUsageStats', args);
      if (raw == null) return {};
      return {
        for (final entry in raw.cast<Map<dynamic, dynamic>>())
          entry['packageName'] as String: (entry['foregroundTimeMs'] as num).toInt(),
      };
    } on PlatformException {
      // Foreground time is supplementary data; degrade gracefully.
      return {};
    }
  }

  AppUsageRecord _recordFromMap(
    Map<dynamic, dynamic> m, {
    required Map<String, int> foregroundTime,
  }) {
    final pkg = m['packageName'] as String;
    return AppUsageRecord(
      packageName:           pkg,
      appName:               m['appName']               as String,
      mobileForegroundBytes: (m['mobileForegroundBytes'] as num).toInt(),
      mobileBackgroundBytes: (m['mobileBackgroundBytes'] as num).toInt(),
      wifiForegroundBytes:   (m['wifiForegroundBytes']   as num).toInt(),
      wifiBackgroundBytes:   (m['wifiBackgroundBytes']   as num).toInt(),
      // Prefer the merged UsageStats value; fall back to the channel-provided value.
      foregroundTimeMs: foregroundTime[pkg] ?? (m['foregroundTimeMs'] as num? ?? 0).toInt(),
      periodStart:  DateTime.fromMillisecondsSinceEpoch(m['periodStart'] as int),
      periodEnd:    DateTime.fromMillisecondsSinceEpoch(m['periodEnd']   as int),
      appIconBase64: m['appIconBase64'] as String?,
      isSystemApp:  (m['isSystemApp'] as bool?) ?? false,
    );
  }
}
