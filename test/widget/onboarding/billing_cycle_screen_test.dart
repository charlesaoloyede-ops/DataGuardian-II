import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:data_guardian/features/alerts/domain/entities/user_preferences.dart';
import 'package:data_guardian/services/storage/shared_prefs_service.dart';
import 'helpers/onboarding_test_helpers.dart';

// ── mocks ─────────────────────────────────────────────────────────────────────

class MockSharedPrefsService extends Mock implements SharedPrefsService {}
class FakeUserPreferences extends Fake implements UserPreferences {}

// ── tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    registerFallbackValue(FakeUserPreferences());
  });

  late MockSharedPrefsService mockPrefs;

  setUp(() {
    mockPrefs = MockSharedPrefsService();
    when(() => mockPrefs.getPreferences()).thenReturn(const UserPreferences());
    when(() => mockPrefs.savePreferences(any())).thenAnswer((_) async {});

    if (GetIt.instance.isRegistered<SharedPrefsService>()) {
      GetIt.instance.unregister<SharedPrefsService>();
    }
    GetIt.instance.registerSingleton<SharedPrefsService>(mockPrefs);
  });

  tearDown(() {
    if (GetIt.instance.isRegistered<SharedPrefsService>()) {
      GetIt.instance.unregister<SharedPrefsService>();
    }
  });

  group('BillingCycleScreen — content', () {
    testWidgets('shows Step 6 of 6 AppBar', (tester) async {
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: buildOnboardingRouter(
            initialLocation: '/onboarding/billing-cycle'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Step 6 of 6'), findsOneWidget);
    });

    testWidgets('shows day tiles in the grid', (tester) async {
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: buildOnboardingRouter(
            initialLocation: '/onboarding/billing-cycle'),
      ));
      await tester.pumpAndSettle();

      // Days in the first row are always visible.
      for (final day in [1, 2, 7]) {
        expect(find.text('$day'), findsOneWidget);
      }
    });

    testWidgets('Save & Continue is disabled when no day selected',
        (tester) async {
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: buildOnboardingRouter(
            initialLocation: '/onboarding/billing-cycle'),
      ));
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Save & Continue'));
      expect(button.onPressed, isNull);
    });

    testWidgets('shows Skip button', (tester) async {
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: buildOnboardingRouter(
            initialLocation: '/onboarding/billing-cycle'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Skip — use Last 30 Days'), findsOneWidget);
    });
  });

  group('BillingCycleScreen — interactions', () {
    testWidgets('selecting a day enables Save & Continue', (tester) async {
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: buildOnboardingRouter(
            initialLocation: '/onboarding/billing-cycle'),
      ));
      await tester.pumpAndSettle();

      // Scroll to and tap day 7 (last tile in first row — always rendered).
      await tester.ensureVisible(find.text('7'));
      await tester.tap(find.text('7'));
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Save & Continue'));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('Save & Continue saves selected day and navigates to Complete',
        (tester) async {
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: buildOnboardingRouter(
            initialLocation: '/onboarding/billing-cycle'),
      ));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('7'));
      await tester.tap(find.text('7'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save & Continue'));
      await tester.pumpAndSettle();

      verify(() => mockPrefs.savePreferences(
            any(
              that: isA<UserPreferences>().having(
                (p) => p.billingCycleStartDay,
                'billingCycleStartDay',
                7,
              ),
            ),
          )).called(1);

      expect(find.text("You're all set!"), findsOneWidget);
    });

    testWidgets('Skip navigates to Complete without saving', (tester) async {
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: buildOnboardingRouter(
            initialLocation: '/onboarding/billing-cycle'),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Skip — use Last 30 Days'));
      await tester.pumpAndSettle();

      verifyNever(() => mockPrefs.savePreferences(any()));
      expect(find.text("You're all set!"), findsOneWidget);
    });
  });
}
