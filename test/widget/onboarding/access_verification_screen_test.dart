import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'helpers/onboarding_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(clearUsageChannel);

  group('AccessVerificationScreen — denied', () {
    setUp(() {
      mockUsageChannel((call) async {
        if (call.method == 'isUsageAccessGranted') return false;
        return null;
      });
    });

    testWidgets('shows step indicator', (tester) async {
      await tester.pumpWidget(MaterialApp.router(
        routerConfig:
            buildOnboardingRouter(initialLocation: '/onboarding/verification'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Step 3 of 6'), findsOneWidget);
    });

    testWidgets('shows loading indicator before channel responds',
        (tester) async {
      final completer = Completer<Object?>();
      mockUsageChannel((_) => completer.future);

      await tester.pumpWidget(MaterialApp.router(
        routerConfig:
            buildOnboardingRouter(initialLocation: '/onboarding/verification'),
      ));
      await tester.pump(); // one frame — channel not yet resolved

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete to avoid leaked async.
      completer.complete(false);
      await tester.pumpAndSettle();
    });

    testWidgets('shows error icon and denied text when permission denied',
        (tester) async {
      await tester.pumpWidget(MaterialApp.router(
        routerConfig:
            buildOnboardingRouter(initialLocation: '/onboarding/verification'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Permission not granted'), findsOneWidget);
    });

    testWidgets('shows Try again button when denied', (tester) async {
      await tester.pumpWidget(MaterialApp.router(
        routerConfig:
            buildOnboardingRouter(initialLocation: '/onboarding/verification'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('Try again navigates back to Usage Access screen',
        (tester) async {
      await tester.pumpWidget(MaterialApp.router(
        routerConfig:
            buildOnboardingRouter(initialLocation: '/onboarding/verification'),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Step 2 of 6'), findsOneWidget);
    });
  });

  group('AccessVerificationScreen — granted', () {
    setUp(() {
      mockUsageChannel((call) async {
        if (call.method == 'isUsageAccessGranted') return true;
        return null;
      });
    });

    testWidgets('shows granted text when permission granted', (tester) async {
      await tester.pumpWidget(MaterialApp.router(
        routerConfig:
            buildOnboardingRouter(initialLocation: '/onboarding/verification'),
      ));
      // Let channel resolve (microtasks) and setState rebuild.
      await tester.pump();
      await tester.pump();

      expect(find.text('Permission granted!'), findsOneWidget);

      // Drain the 800ms navigation timer so the test ends clean.
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();
    });

    testWidgets('does not show Try again button when granted', (tester) async {
      await tester.pumpWidget(MaterialApp.router(
        routerConfig:
            buildOnboardingRouter(initialLocation: '/onboarding/verification'),
      ));
      await tester.pump();
      await tester.pump();

      expect(find.text('Try again'), findsNothing);

      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();
    });

    testWidgets('auto-navigates to Notification screen after delay',
        (tester) async {
      await tester.pumpWidget(MaterialApp.router(
        routerConfig:
            buildOnboardingRouter(initialLocation: '/onboarding/verification'),
      ));
      await tester.pumpAndSettle();
      // Advance past the 800 ms navigation delay.
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();

      expect(find.text('Step 5 of 6'), findsOneWidget);
    });
  });
}
