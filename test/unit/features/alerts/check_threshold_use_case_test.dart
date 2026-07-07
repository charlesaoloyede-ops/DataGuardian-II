import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:data_guardian/features/alerts/domain/entities/user_preferences.dart';
import 'package:data_guardian/features/alerts/domain/use_cases/check_threshold_use_case.dart';
import 'package:data_guardian/features/app_usage/domain/i_network_stats_repository.dart';
import 'package:data_guardian/services/storage/shared_prefs_service.dart';

// ── mocks ─────────────────────────────────────────────────────────────────────

class MockNetworkRepo extends Mock implements INetworkStatsRepository {}
class MockPrefsService extends Mock implements SharedPrefsService {}

// ── tests ─────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockNetworkRepo networkRepo;
  late MockPrefsService prefs;
  late CheckThresholdUseCase useCase;

  setUp(() {
    networkRepo = MockNetworkRepo();
    prefs       = MockPrefsService();
    useCase     = CheckThresholdUseCase(networkRepo, prefs);
  });

  // ── no thresholds set ─────────────────────────────────────────────────────

  test('returns empty list when no thresholds are configured', () async {
    when(() => prefs.getPreferences())
        .thenReturn(const UserPreferences()); // both limits null

    final result = await useCase();
    expect(result, isEmpty);
    verifyNever(() => networkRepo.getTotalMobileUsage(
        start: any(named: 'start'), end: any(named: 'end')));
  });

  // ── daily threshold ───────────────────────────────────────────────────────

  group('daily threshold', () {
    const limit = 500 * 1000 * 1000; // 500 MB

    setUp(() {
      when(() => prefs.getPreferences())
          .thenReturn(const UserPreferences(dailyThresholdBytes: limit));
    });

    test('exceeded — returned in results', () async {
      when(() => networkRepo.getTotalMobileUsage(
              start: any(named: 'start'), end: any(named: 'end')))
          .thenAnswer((_) async => 600 * 1000 * 1000); // 600 MB > 500 MB

      final result = await useCase();

      expect(result, hasLength(1));
      expect(result.first.type, ThresholdType.daily);
      expect(result.first.isExceeded, isTrue);
      expect(result.first.usageBytes, 600 * 1000 * 1000);
      expect(result.first.limitBytes, limit);
    });

    test('not exceeded — empty results', () async {
      when(() => networkRepo.getTotalMobileUsage(
              start: any(named: 'start'), end: any(named: 'end')))
          .thenAnswer((_) async => 400 * 1000 * 1000); // 400 MB < 500 MB

      final result = await useCase();
      expect(result, isEmpty);
    });

    test('exactly at limit — not exceeded (strictly greater)', () async {
      when(() => networkRepo.getTotalMobileUsage(
              start: any(named: 'start'), end: any(named: 'end')))
          .thenAnswer((_) async => limit);

      final result = await useCase();
      expect(result, isEmpty);
    });
  });

  // ── weekly threshold ──────────────────────────────────────────────────────

  group('weekly threshold', () {
    const limit = 2 * 1000 * 1000 * 1000; // 2 GB

    setUp(() {
      when(() => prefs.getPreferences())
          .thenReturn(const UserPreferences(weeklyThresholdBytes: limit));
    });

    test('exceeded — returned in results', () async {
      when(() => networkRepo.getTotalMobileUsage(
              start: any(named: 'start'), end: any(named: 'end')))
          .thenAnswer((_) async => 3 * 1000 * 1000 * 1000);

      final result = await useCase();

      expect(result, hasLength(1));
      expect(result.first.type, ThresholdType.weekly);
    });
  });

  // ── both thresholds set ───────────────────────────────────────────────────

  group('both thresholds set', () {
    setUp(() {
      when(() => prefs.getPreferences()).thenReturn(const UserPreferences(
        dailyThresholdBytes:  500 * 1000 * 1000,
        weeklyThresholdBytes: 2 * 1000 * 1000 * 1000,
      ));
    });

    test('both exceeded — two results', () async {
      when(() => networkRepo.getTotalMobileUsage(
              start: any(named: 'start'), end: any(named: 'end')))
          .thenAnswer((_) async => 3 * 1000 * 1000 * 1000); // exceeds both

      final result = await useCase();

      expect(result, hasLength(2));
      expect(result.map((r) => r.type),
          containsAll([ThresholdType.daily, ThresholdType.weekly]));
    });

    test('only daily exceeded — one result', () async {
      // Return different values per call based on date range duration.
      var callCount = 0;
      when(() => networkRepo.getTotalMobileUsage(
              start: any(named: 'start'), end: any(named: 'end')))
          .thenAnswer((_) async {
        callCount++;
        // First call = daily (today range, short), second = weekly (longer).
        return callCount == 1 ? 600 * 1000 * 1000 : 1 * 1000 * 1000 * 1000;
      });

      final result = await useCase();
      // Daily: 600 MB > 500 MB → exceeded.
      // Weekly: 1 GB < 2 GB → not exceeded.
      expect(result.where((r) => r.type == ThresholdType.daily), hasLength(1));
    });
  });

  // ── fractionUsed ──────────────────────────────────────────────────────────

  group('ThresholdCheckResult.fractionUsed', () {
    test('returns correct fraction', () {
      const r = ThresholdCheckResult(
        type: ThresholdType.daily,
        isExceeded: true,
        usageBytes: 750 * 1000 * 1000,
        limitBytes: 1000 * 1000 * 1000,
      );
      expect(r.fractionUsed, closeTo(0.75, 0.001));
    });

    test('clamps to 2.0 when massively over limit', () {
      const r = ThresholdCheckResult(
        type: ThresholdType.daily,
        isExceeded: true,
        usageBytes: 10 * 1000 * 1000 * 1000,
        limitBytes: 1000 * 1000 * 1000,
      );
      expect(r.fractionUsed, 2.0);
    });

    test('returns 0 when limitBytes is 0', () {
      const r = ThresholdCheckResult(
        type: ThresholdType.daily,
        isExceeded: false,
        usageBytes: 100,
        limitBytes: 0,
      );
      expect(r.fractionUsed, 0);
    });
  });
}
