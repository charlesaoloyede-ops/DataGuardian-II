import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:data_guardian/features/app_usage/data/daily_usage_repository_impl.dart';
import 'package:data_guardian/features/app_usage/domain/entities/daily_usage_summary.dart';
import 'package:data_guardian/services/storage/hive_service.dart';

// ── mocks ─────────────────────────────────────────────────────────────────────

class MockHiveService extends Mock implements HiveService {}
class MockBox extends Mock implements Box<DailyUsageSummary> {}
class FakeDailyUsageSummary extends Fake implements DailyUsageSummary {}

// ── helpers ───────────────────────────────────────────────────────────────────

DailyUsageSummary _summary({
  required DateTime date,
  int totalMobileBytes = 50 * 1000 * 1000,
  int mobileForegroundBytes = 40 * 1000 * 1000,
  int mobileBackgroundBytes = 10 * 1000 * 1000,
  int totalWifiBytes = 20 * 1000 * 1000,
  bool isAnomaly = false,
}) =>
    DailyUsageSummary(
      date: date,
      totalMobileBytes: totalMobileBytes,
      mobileForegroundBytes: mobileForegroundBytes,
      mobileBackgroundBytes: mobileBackgroundBytes,
      totalWifiBytes: totalWifiBytes,
      isAnomaly: isAnomaly,
    );

void main() {
  setUpAll(() {
    registerFallbackValue(FakeDailyUsageSummary());
  });

  late MockHiveService hive;
  late MockBox box;
  late DailyUsageRepositoryImpl repo;

  setUp(() {
    hive = MockHiveService();
    box  = MockBox();
    when(() => hive.dailyUsageBox).thenReturn(box);
    repo = DailyUsageRepositoryImpl(hive);
  });

  // ── saveDailySummary ───────────────────────────────────────────────────────

  group('saveDailySummary', () {
    test('writes summary to box with correct date key', () async {
      final summary = _summary(date: DateTime(2025, 6, 15));
      when(() => box.put(any(), any())).thenAnswer((_) async {});

      await repo.saveDailySummary(summary);

      verify(() => box.put('2025-06-15', summary)).called(1);
    });

    test('pads single-digit month and day', () async {
      final summary = _summary(date: DateTime(2025, 1, 5));
      when(() => box.put(any(), any())).thenAnswer((_) async {});

      await repo.saveDailySummary(summary);

      verify(() => box.put('2025-01-05', summary)).called(1);
    });
  });

  // ── getLast7Days ───────────────────────────────────────────────────────────

  group('getLast7Days', () {
    test('returns summaries within the last 7 days sorted ascending', () async {
      final now = DateTime.now();
      final summaries = [
        _summary(date: now.subtract(const Duration(days: 1))),
        _summary(date: now.subtract(const Duration(days: 5))),
        _summary(date: now.subtract(const Duration(days: 3))),
        // Outside 7 days — should be excluded.
        _summary(date: now.subtract(const Duration(days: 8))),
      ];
      when(() => box.values).thenReturn(summaries);

      final result = await repo.getLast7Days();

      expect(result, hasLength(3));
      expect(result.first.date.isBefore(result.last.date), isTrue);
    });

    test('returns empty list when box is empty', () async {
      when(() => box.values).thenReturn([]);
      final result = await repo.getLast7Days();
      expect(result, isEmpty);
    });
  });
}
