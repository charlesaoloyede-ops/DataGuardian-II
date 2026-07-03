import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:data_guardian/core/analytics/i_analytics_service.dart';
import 'package:data_guardian/core/constants/app_constants.dart';
import 'package:data_guardian/features/app_usage/data/app_usage_repository_impl.dart';

// ── mocks ────────────────────────────────────────────────────────────────────

class MockAnalyticsService extends Mock implements IAnalyticsService {}

// ── helpers ──────────────────────────────────────────────────────────────────

const _networkChannel = MethodChannel(AppConstants.networkStatsChannel);
const _usageChannel   = MethodChannel(AppConstants.usageStatsChannel);

/// Sets the mock handler for [channel]; returns a teardown callback.
void _mockChannel(MethodChannel channel, Future<Object?> Function(MethodCall) handler) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, handler);
}

void _clearChannel(MethodChannel channel) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null);
}

Map<String, Object?> _fakeAppMap({
  String packageName          = 'com.whatsapp',
  String appName              = 'WhatsApp',
  int mobileForegroundBytes   = 200 * 1000 * 1000,
  int mobileBackgroundBytes   = 50  * 1000 * 1000,
  int wifiForegroundBytes     = 100 * 1000 * 1000,
  int wifiBackgroundBytes     = 10  * 1000 * 1000,
  bool isSystemApp            = false,
}) =>
    {
      'packageName':           packageName,
      'appName':               appName,
      'mobileForegroundBytes': mobileForegroundBytes,
      'mobileBackgroundBytes': mobileBackgroundBytes,
      'wifiForegroundBytes':   wifiForegroundBytes,
      'wifiBackgroundBytes':   wifiBackgroundBytes,
      'foregroundTimeMs':      0,
      'periodStart':           DateTime(2025, 6, 1).millisecondsSinceEpoch,
      'periodEnd':             DateTime(2025, 6, 30).millisecondsSinceEpoch,
      'appIconBase64':         null,
      'isSystemApp':           isSystemApp,
    };

// ── tests ─────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAnalyticsService analytics;
  late AppUsageRepositoryImpl repository;

  final start = DateTime(2025, 6, 1);
  final end   = DateTime(2025, 6, 30);

  setUp(() {
    analytics  = MockAnalyticsService();
    repository = AppUsageRepositoryImpl(analytics);

    // Default: usage-stats channel returns empty foreground list.
    _mockChannel(_usageChannel, (call) async {
      if (call.method == 'isUsageAccessGranted') return true;
      if (call.method == 'getUsageStats') return <Object?>[];
      return null;
    });
  });

  tearDown(() {
    _clearChannel(_networkChannel);
    _clearChannel(_usageChannel);
  });

  // ── isUsageAccessGranted ─────────────────────────────────────────────────

  group('isUsageAccessGranted', () {
    test('returns true when channel returns true', () async {
      _mockChannel(_usageChannel, (call) async => true);
      expect(await repository.isUsageAccessGranted(), isTrue);
    });

    test('returns false when channel returns false', () async {
      _mockChannel(_usageChannel, (call) async => false);
      expect(await repository.isUsageAccessGranted(), isFalse);
    });

    test('returns false when channel returns null', () async {
      _mockChannel(_usageChannel, (call) async => null);
      expect(await repository.isUsageAccessGranted(), isFalse);
    });
  });

  // ── getAppUsage — happy path ─────────────────────────────────────────────

  group('getAppUsage — parsing', () {
    setUp(() {
      _mockChannel(_networkChannel, (call) async {
        if (call.method == 'getNetworkStats') return [_fakeAppMap()];
        return null;
      });
    });

    test('parses a single app record correctly', () async {
      final records = await repository.getAppUsage(start: start, end: end);

      expect(records, hasLength(1));
      final r = records.first;
      expect(r.packageName,           'com.whatsapp');
      expect(r.appName,               'WhatsApp');
      expect(r.mobileForegroundBytes, 200 * 1000 * 1000);
      expect(r.mobileBackgroundBytes, 50  * 1000 * 1000);
      expect(r.wifiForegroundBytes,   100 * 1000 * 1000);
      expect(r.wifiBackgroundBytes,   10  * 1000 * 1000);
      expect(r.totalMobileBytes,      250 * 1000 * 1000);
      expect(r.totalWifiBytes,        110 * 1000 * 1000);
      expect(r.isSystemApp,           isFalse);
      expect(r.appIconBase64,         isNull);
    });

    test('passes correct date range to channel', () async {
      MethodCall? captured;
      _mockChannel(_networkChannel, (call) async {
        captured = call;
        return <Object?>[];
      });

      await repository.getAppUsage(start: start, end: end);

      expect(captured?.method, 'getNetworkStats');
      expect(captured?.arguments['startMs'], start.millisecondsSinceEpoch);
      expect(captured?.arguments['endMs'],   end.millisecondsSinceEpoch);
    });

    test('parses multiple records', () async {
      _mockChannel(_networkChannel, (call) async => [
        _fakeAppMap(packageName: 'com.whatsapp', appName: 'WhatsApp'),
        _fakeAppMap(packageName: 'com.instagram.android', appName: 'Instagram',
            mobileForegroundBytes: 80 * 1000 * 1000, mobileBackgroundBytes: 20 * 1000 * 1000,
            wifiForegroundBytes: 0, wifiBackgroundBytes: 0),
      ]);

      final records = await repository.getAppUsage(start: start, end: end);
      expect(records, hasLength(2));
      expect(records.map((r) => r.packageName), containsAll(['com.whatsapp', 'com.instagram.android']));
    });

    test('returns empty list when channel returns null', () async {
      _mockChannel(_networkChannel, (call) async => null);
      final records = await repository.getAppUsage(start: start, end: end);
      expect(records, isEmpty);
    });

    test('returns empty list when channel returns empty list', () async {
      _mockChannel(_networkChannel, (call) async => <Object?>[]);
      final records = await repository.getAppUsage(start: start, end: end);
      expect(records, isEmpty);
    });
  });

  // ── foreground time merge ─────────────────────────────────────────────────

  group('getAppUsage — foreground time merge', () {
    test('merges foreground time from usage-stats channel', () async {
      _mockChannel(_networkChannel, (call) async => [_fakeAppMap()]);
      _mockChannel(_usageChannel, (call) async {
        if (call.method == 'getUsageStats') {
          return [{'packageName': 'com.whatsapp', 'foregroundTimeMs': 3600000}];
        }
        return true;
      });

      final records = await repository.getAppUsage(start: start, end: end);
      expect(records.first.foregroundTimeMs, 3600000);
    });

    test('falls back to channel foregroundTimeMs when usage-stats fails', () async {
      _mockChannel(_networkChannel, (call) async => [
        _fakeAppMap()..['foregroundTimeMs'] = 1800000,
      ]);
      _mockChannel(_usageChannel, (call) async {
        if (call.method == 'getUsageStats') {
          throw PlatformException(code: 'USAGE_STATS_RESTRICTED');
        }
        return true;
      });

      // Should not throw; foreground time falls back to network-channel value.
      final records = await repository.getAppUsage(start: start, end: end);
      expect(records, hasLength(1));
    });

    test('uses 0 for foreground time when both sources absent', () async {
      _mockChannel(_networkChannel, (call) async => [_fakeAppMap()]);
      // usage channel returns empty list (default setUp)

      final records = await repository.getAppUsage(start: start, end: end);
      expect(records.first.foregroundTimeMs, 0);
    });
  });

  // ── error handling ────────────────────────────────────────────────────────

  group('getAppUsage — error handling', () {
    test('re-throws USAGE_ACCESS_REQUIRED PlatformException', () async {
      _mockChannel(_networkChannel, (_) async =>
          throw PlatformException(code: 'USAGE_ACCESS_REQUIRED', message: 'Permission needed'));

      expect(
        () => repository.getAppUsage(start: start, end: end),
        throwsA(isA<PlatformException>().having((e) => e.code, 'code', 'USAGE_ACCESS_REQUIRED')),
      );
    });

    test('returns empty list on OEM restriction and logs analytics event', () async {
      when(() => analytics.logEvent(any(), properties: any(named: 'properties')))
          .thenAnswer((_) async {});

      _mockChannel(_networkChannel, (_) async =>
          throw PlatformException(code: 'NETWORK_STATS_RESTRICTED', message: 'OEM denied'));

      final records = await repository.getAppUsage(start: start, end: end);

      expect(records, isEmpty);
      verify(() => analytics.logEvent(
        AnalyticsEvents.networkStatsRestricted,
        properties: any(named: 'properties'),
      )).called(1);
    });

    test('returns empty list on generic PlatformException and logs event', () async {
      when(() => analytics.logEvent(any(), properties: any(named: 'properties')))
          .thenAnswer((_) async {});

      _mockChannel(_networkChannel, (_) async =>
          throw PlatformException(code: 'NETWORK_STATS_FAILED', message: 'Unknown error'));

      final records = await repository.getAppUsage(start: start, end: end);
      expect(records, isEmpty);
    });
  });

  // ── getTotalMobileUsage ───────────────────────────────────────────────────

  group('getTotalMobileUsage', () {
    test('sums totalMobileBytes across all apps', () async {
      _mockChannel(_networkChannel, (call) async => [
        _fakeAppMap(mobileForegroundBytes: 200 * 1000 * 1000, mobileBackgroundBytes: 50 * 1000 * 1000),
        _fakeAppMap(packageName: 'com.instagram.android', appName: 'Instagram',
            mobileForegroundBytes: 80 * 1000 * 1000, mobileBackgroundBytes: 20 * 1000 * 1000,
            wifiForegroundBytes: 0, wifiBackgroundBytes: 0),
      ]);

      final total = await repository.getTotalMobileUsage(start: start, end: end);
      expect(total, (200 + 50 + 80 + 20) * 1000 * 1000);
    });

    test('returns 0 when no apps have usage', () async {
      _mockChannel(_networkChannel, (call) async => <Object?>[]);
      final total = await repository.getTotalMobileUsage(start: start, end: end);
      expect(total, 0);
    });
  });

  // ── isSystemApp flag ──────────────────────────────────────────────────────

  group('isSystemApp flag', () {
    test('correctly maps isSystemApp = true', () async {
      _mockChannel(_networkChannel, (call) async => [_fakeAppMap(isSystemApp: true)]);
      final records = await repository.getAppUsage(start: start, end: end);
      expect(records.first.isSystemApp, isTrue);
    });

    test('defaults isSystemApp to false when field absent from map', () async {
      final mapWithoutFlag = Map<String, Object?>.from(_fakeAppMap())..remove('isSystemApp');
      _mockChannel(_networkChannel, (call) async => [mapWithoutFlag]);
      final records = await repository.getAppUsage(start: start, end: end);
      expect(records.first.isSystemApp, isFalse);
    });
  });
}
