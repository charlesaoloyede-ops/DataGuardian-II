import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:data_guardian/services/background/i_background_service_manager.dart';
import 'package:data_guardian/services/storage/shared_prefs_service.dart';
import 'helpers/onboarding_test_helpers.dart';

// ── mocks ─────────────────────────────────────────────────────────────────────

class MockSharedPrefsService extends Mock implements SharedPrefsService {}
class MockBackgroundServiceManager extends Mock implements IBackgroundServiceManager {}

// ── tests ─────────────────────────────────────────────────────────────────────

void main() {
  late MockSharedPrefsService mockPrefs;
  late MockBackgroundServiceManager mockBgManager;

  setUp(() {
    mockPrefs     = MockSharedPrefsService();
    mockBgManager = MockBackgroundServiceManager();

    when(() => mockPrefs.setOnboardingComplete(any())).thenAnswer((_) async {});
    when(() => mockBgManager.startService()).thenAnswer((_) async {});

    if (GetIt.instance.isRegistered<SharedPrefsService>()) {
      GetIt.instance.unregister<SharedPrefsService>();
    }
    if (GetIt.instance.isRegistered<IBackgroundServiceManager>()) {
      GetIt.instance.unregister<IBackgroundServiceManager>();
    }
    GetIt.instance.registerSingleton<SharedPrefsService>(mockPrefs);
    GetIt.instance.registerSingleton<IBackgroundServiceManager>(mockBgManager);
  });

  tearDown(() {
    if (GetIt.instance.isRegistered<SharedPrefsService>()) {
      GetIt.instance.unregister<SharedPrefsService>();
    }
    if (GetIt.instance.isRegistered<IBackgroundServiceManager>()) {
      GetIt.instance.unregister<IBackgroundServiceManager>();
    }
  });

  group('OnboardingCompleteScreen — content', () {
    testWidgets('shows all set heading', (tester) async {
      await tester.pumpWidget(MaterialApp.router(
        routerConfig:
            buildOnboardingRouter(initialLocation: '/onboarding/complete'),
      ));
      await tester.pumpAndSettle();

      expect(find.text("You're all set!"), findsOneWidget);
    });

    testWidgets('shows subtitle text', (tester) async {
      await tester.pumpWidget(MaterialApp.router(
        routerConfig:
            buildOnboardingRouter(initialLocation: '/onboarding/complete'),
      ));
      await tester.pumpAndSettle();

      expect(
        find.text(
            'Data Guardian is ready to monitor your usage and send you alerts.'),
        findsOneWidget,
      );
    });

    testWidgets('shows Go to Dashboard button', (tester) async {
      await tester.pumpWidget(MaterialApp.router(
        routerConfig:
            buildOnboardingRouter(initialLocation: '/onboarding/complete'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Go to Dashboard'), findsOneWidget);
    });

    testWidgets('shows check circle icon', (tester) async {
      await tester.pumpWidget(MaterialApp.router(
        routerConfig:
            buildOnboardingRouter(initialLocation: '/onboarding/complete'),
      ));
      await tester.pumpAndSettle();

      expect(
        find.byIcon(Icons.check_circle_rounded),
        findsOneWidget,
      );
    });
  });

  group('OnboardingCompleteScreen — actions', () {
    testWidgets(
        'tapping Go to Dashboard calls setOnboardingComplete(true) and navigates',
        (tester) async {
      await tester.pumpWidget(MaterialApp.router(
        routerConfig:
            buildOnboardingRouter(initialLocation: '/onboarding/complete'),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Go to Dashboard'));
      await tester.pumpAndSettle();

      verify(() => mockPrefs.setOnboardingComplete(true)).called(1);
      verify(() => mockBgManager.startService()).called(1);
      // Dashboard stub text confirms navigation succeeded.
      expect(find.text('Dashboard'), findsOneWidget);
    });
  });
}
