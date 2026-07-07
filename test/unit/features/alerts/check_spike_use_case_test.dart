import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:data_guardian/features/alerts/domain/entities/user_preferences.dart';
import 'package:data_guardian/features/alerts/domain/use_cases/check_spike_use_case.dart';
import 'package:data_guardian/features/app_usage/domain/entities/daily_usage_summary.dart';
import 'package:data_guardian/features/app_usage/domain/i_daily_usage_repository.dart';
import 'package:data_guardian/services/storage/shared_prefs_service.dart';

// ── mocks ─────────────────────────────────────────────────────────────────────

class MockDailyRepo extends Mock implements IDailyUsageRepository {}
class MockPrefsService extends Mock implements SharedPrefsService {}

// ── helpers ───────────────────────────────────────────────────────────────────

DailyUsageSummary _day(int mobileBytes) => DailyUsageSummary(
      date: DateTime.now(),
      totalMobileBytes: mobileBytes,
      mobileForegroundBytes: mobileBytes,
      mobileBackgroundBytes: 0,
      totalWifiBytes: 0,
    );

List<DailyUsageSummary> _baseline(int count, int bytesEach) =>
    List.generate(count, (_) => _day(bytesEach));

void main() {
  late MockDailyRepo dailyRepo;
  late MockPrefsService prefs;
  late CheckSpikeUseCase useCase;

  const defaultPrefs = UserPreferences(spikeThresholdMultiplier: 1.75);

  setUp(() {
    dailyRepo = MockDailyRepo();
    prefs     = MockPrefsService();
    useCase   = CheckSpikeUseCase(dailyRepo, prefs);
    when(() => prefs.getPreferences()).thenReturn(defaultPrefs);
  });

  // ── insufficient baseline ──────────────────────────────────────────────────

  group('insufficient baseline', () {
    test('returns null when fewer than minBaselineDays (3) days available', () async {
      when(() => dailyRepo.getBaselineDays(any())).thenAnswer((_) async => _baseline(2, 50 * 1000 * 1000));

      final result = await useCase(_day(200 * 1000 * 1000));
      expect(result, isNull);
    });

    test('returns null when baseline is empty', () async {
      when(() => dailyRepo.getBaselineDays(any())).thenAnswer((_) async => []);
      final result = await useCase(_day(100 * 1000 * 1000));
      expect(result, isNull);
    });
  });

  // ── spike detection ────────────────────────────────────────────────────────

  group('spike detection', () {
    // 7 baseline days × 100 MB each → avg 100 MB. Spike at > 175 MB (×1.75).

    test('detects spike when today > avg × multiplier', () async {
      when(() => dailyRepo.getBaselineDays(any()))
          .thenAnswer((_) async => _baseline(7, 100 * 1000 * 1000));

      // 200 MB > 100 MB × 1.75 = 175 MB → spike
      final result = await useCase(_day(200 * 1000 * 1000));

      expect(result, isNotNull);
      expect(result!.isSpike, isTrue);
      expect(result.todayBytes, 200 * 1000 * 1000);
      expect(result.baselineAvgBytes, closeTo(100 * 1000 * 1000, 1));
    });

    test('no spike when today == avg × multiplier (boundary)', () async {
      when(() => dailyRepo.getBaselineDays(any()))
          .thenAnswer((_) async => _baseline(7, 100 * 1000 * 1000));

      // Exactly 175 MB — not strictly greater, so no spike.
      final result = await useCase(_day(175 * 1000 * 1000));
      expect(result!.isSpike, isFalse);
    });

    test('no spike when today is below threshold', () async {
      when(() => dailyRepo.getBaselineDays(any()))
          .thenAnswer((_) async => _baseline(7, 100 * 1000 * 1000));

      final result = await useCase(_day(50 * 1000 * 1000));
      expect(result!.isSpike, isFalse);
    });

    test('respects custom multiplier from preferences', () async {
      when(() => prefs.getPreferences()).thenReturn(
        const UserPreferences(spikeThresholdMultiplier: 2.0),
      );
      when(() => dailyRepo.getBaselineDays(any()))
          .thenAnswer((_) async => _baseline(5, 100 * 1000 * 1000));

      // 190 MB — spike at ×1.75 but NOT at ×2.0.
      final result = await useCase(_day(190 * 1000 * 1000));
      expect(result!.isSpike, isFalse);
    });

    test('no spike when baseline avg is 0 (no prior traffic)', () async {
      when(() => dailyRepo.getBaselineDays(any()))
          .thenAnswer((_) async => _baseline(5, 0));

      final result = await useCase(_day(100 * 1000 * 1000));
      // avgBaseline == 0 → guard prevents false positive spike.
      expect(result!.isSpike, isFalse);
    });

    test('uses all baseline days when exactly minBaselineDays available', () async {
      // Exactly 3 days (minBaseline)  → should proceed.
      when(() => dailyRepo.getBaselineDays(any()))
          .thenAnswer((_) async => _baseline(3, 100 * 1000 * 1000));

      final result = await useCase(_day(200 * 1000 * 1000));
      expect(result, isNotNull);
      expect(result!.isSpike, isTrue);
    });
  });

  // ── result fields ──────────────────────────────────────────────────────────

  group('result fields', () {
    test('result carries correct multiplier and baseline avg', () async {
      when(() => prefs.getPreferences()).thenReturn(
        const UserPreferences(spikeThresholdMultiplier: 1.5),
      );
      when(() => dailyRepo.getBaselineDays(any()))
          .thenAnswer((_) async => _baseline(4, 80 * 1000 * 1000));

      final result = await useCase(_day(150 * 1000 * 1000));

      expect(result!.multiplierUsed, 1.5);
      expect(result.baselineAvgBytes, closeTo(80 * 1000 * 1000, 1));
    });
  });
}
