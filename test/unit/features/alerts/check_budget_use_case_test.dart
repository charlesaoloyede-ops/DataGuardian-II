import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:data_guardian/features/alerts/domain/use_cases/check_budget_use_case.dart';
import 'package:data_guardian/features/app_usage/domain/entities/app_usage_record.dart';
import 'package:data_guardian/services/storage/shared_prefs_service.dart';

// ── mocks ─────────────────────────────────────────────────────────────────────

class MockPrefsService extends Mock implements SharedPrefsService {}

// ── helpers ───────────────────────────────────────────────────────────────────

final _cycleStart = DateTime(2025, 6, 1);

AppUsageRecord _app(String packageName, int mobileBytes) => AppUsageRecord(
      packageName: packageName,
      appName: packageName,
      mobileForegroundBytes: mobileBytes,
      mobileBackgroundBytes: 0,
      wifiForegroundBytes: 0,
      wifiBackgroundBytes: 0,
      foregroundTimeMs: 0,
      periodStart: _cycleStart,
      periodEnd: DateTime(2025, 6, 15),
    );

// ── tests ─────────────────────────────────────────────────────────────────────

void main() {
  late MockPrefsService prefs;
  late CheckBudgetUseCase useCase;

  setUp(() {
    prefs = MockPrefsService();
    when(() => prefs.budgetAlertCycleKey).thenReturn(null);
    when(() => prefs.getBudgetAlertProgress()).thenReturn({});
    when(() => prefs.saveBudgetAlertProgress(any())).thenAnswer((_) async {});
    when(() => prefs.setBudgetAlertCycleKey(any())).thenAnswer((_) async {});
    useCase = CheckBudgetUseCase(prefs);
  });

  test('returns empty list when no budgets are set', () async {
    when(() => prefs.getAppBudgets()).thenReturn({});

    final result = await useCase([_app('com.a', 100)], _cycleStart);

    expect(result, isEmpty);
  });

  test('returns empty list when usage is below the lowest threshold', () async {
    when(() => prefs.getAppBudgets()).thenReturn({'com.a': 1000});

    final result = await useCase([_app('com.a', 600)], _cycleStart); // 60%

    expect(result, isEmpty);
  });

  test('reports the highest newly-crossed threshold', () async {
    when(() => prefs.getAppBudgets()).thenReturn({'com.a': 1000});

    final result = await useCase([_app('com.a', 950)], _cycleStart); // 95%

    expect(result, hasLength(1));
    expect(result.first.packageName, 'com.a');
    expect(result.first.thresholdPercent, 90);
  });

  test('reports 100% when usage meets or exceeds the budget', () async {
    when(() => prefs.getAppBudgets()).thenReturn({'com.a': 1000});

    final result = await useCase([_app('com.a', 1200)], _cycleStart);

    expect(result, hasLength(1));
    expect(result.first.thresholdPercent, 100);
  });

  test('does not re-report a threshold already notified this cycle', () async {
    when(() => prefs.getAppBudgets()).thenReturn({'com.a': 1000});
    when(() => prefs.budgetAlertCycleKey).thenReturn('2025-06-01');
    when(() => prefs.getBudgetAlertProgress()).thenReturn({'com.a': 80});

    final result = await useCase([_app('com.a', 850)], _cycleStart); // still in the 80s

    expect(result, isEmpty);
  });

  test('reports a higher threshold once usage climbs past it', () async {
    when(() => prefs.getAppBudgets()).thenReturn({'com.a': 1000});
    when(() => prefs.budgetAlertCycleKey).thenReturn('2025-06-01');
    when(() => prefs.getBudgetAlertProgress()).thenReturn({'com.a': 80});

    final result = await useCase([_app('com.a', 950)], _cycleStart); // now 95%

    expect(result, hasLength(1));
    expect(result.first.thresholdPercent, 90);
  });

  test('resets progress when the billing cycle has rolled over', () async {
    when(() => prefs.getAppBudgets()).thenReturn({'com.a': 1000});
    // Stored progress belongs to a previous cycle.
    when(() => prefs.budgetAlertCycleKey).thenReturn('2025-05-01');
    when(() => prefs.getBudgetAlertProgress()).thenReturn({'com.a': 100});

    final result = await useCase([_app('com.a', 750)], _cycleStart); // 75% of new cycle

    expect(result, hasLength(1));
    expect(result.first.thresholdPercent, 70);
  });

  test('ignores apps without a budget set', () async {
    when(() => prefs.getAppBudgets()).thenReturn({'com.a': 1000});

    final result = await useCase(
      [_app('com.a', 950), _app('com.b', 999999)],
      _cycleStart,
    );

    expect(result, hasLength(1));
    expect(result.first.packageName, 'com.a');
  });

  test('checks multiple apps independently', () async {
    when(() => prefs.getAppBudgets())
        .thenReturn({'com.a': 1000, 'com.b': 500});

    final result = await useCase(
      [_app('com.a', 950), _app('com.b', 300)], // com.b at 60% — below threshold
      _cycleStart,
    );

    expect(result, hasLength(1));
    expect(result.first.packageName, 'com.a');
  });

  test('persists updated progress and cycle key after a breach', () async {
    when(() => prefs.getAppBudgets()).thenReturn({'com.a': 1000});

    await useCase([_app('com.a', 950)], _cycleStart);

    final captured = verify(() => prefs.saveBudgetAlertProgress(captureAny()))
        .captured
        .single as Map<String, int>;
    expect(captured['com.a'], 90);
    verify(() => prefs.setBudgetAlertCycleKey('2025-06-01')).called(1);
  });
}
