import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import '../domain/entities/app_usage_record.dart';
import '../domain/i_network_stats_repository.dart';
import '../../../core/analytics/i_analytics_service.dart';
import '../../../core/constants/app_constants.dart';

/// Bridges Dart to [NetworkStatsChannel.kt] and [UsageStatsChannel.kt].
@LazySingleton(as: INetworkStatsRepository)
class AppUsageRepositoryImpl implements INetworkStatsRepository {
  static const _networkChannel =
      MethodChannel(AppConstants.networkStatsChannel);
  static const _usageChannel = MethodChannel(AppConstants.usageStatsChannel);

  final IAnalyticsService _analytics;
  AppUsageRepositoryImpl(this._analytics);

  @override
  Future<bool> isUsageAccessGranted() async {
    final result =
        await _usageChannel.invokeMethod<bool>('isUsageAccessGranted');
    return result ?? false;
  }

  @override
  Future<List<AppUsageRecord>> getAppUsage({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final raw = await _networkChannel.invokeMethod<List<dynamic>>(
        'getNetworkStats',
        {
          'startMs': start.millisecondsSinceEpoch,
          'endMs': end.millisecondsSinceEpoch,
        },
      );
      if (raw == null) return [];
      return raw
          .cast<Map<dynamic, dynamic>>()
          .map(_recordFromMap)
          .toList();
    } on PlatformException catch (e) {
      if (e.code == 'USAGE_ACCESS_REQUIRED') rethrow;
      // OEM restriction — log and return empty
      await _analytics.logEvent(
        AnalyticsEvents.networkStatsRestricted,
        properties: {'error': e.message},
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

  AppUsageRecord _recordFromMap(Map<dynamic, dynamic> m) {
    return AppUsageRecord(
      packageName: m['packageName'] as String,
      appName: m['appName'] as String,
      mobileForegroundBytes: (m['mobileForegroundBytes'] as num).toInt(),
      mobileBackgroundBytes: (m['mobileBackgroundBytes'] as num).toInt(),
      wifiForegroundBytes: (m['wifiForegroundBytes'] as num).toInt(),
      wifiBackgroundBytes: (m['wifiBackgroundBytes'] as num).toInt(),
      foregroundTimeMs: (m['foregroundTimeMs'] as num? ?? 0).toInt(),
      periodStart:
          DateTime.fromMillisecondsSinceEpoch(m['periodStart'] as int),
      periodEnd: DateTime.fromMillisecondsSinceEpoch(m['periodEnd'] as int),
      appIconBase64: m['appIconBase64'] as String?,
      isSystemApp: (m['isSystemApp'] as bool?) ?? false,
    );
  }
}
