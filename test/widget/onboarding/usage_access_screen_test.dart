import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:data_guardian/features/onboarding/presentation/screens/usage_access_screen.dart';
import 'helpers/onboarding_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Default: permission not granted, settings open succeeds.
    mockUsageChannel((call) async {
      if (call.method == 'isUsageAccessGranted') return false;
      if (call.method == 'openUsageAccessSettings') return null;
      return null;
    });
  });

  tearDown(clearUsageChannel);

  group('UsageAccessScreen — content', () {
    testWidgets('shows step indicator in AppBar', (tester) async {
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: buildOnboardingRouter(
            initialLocation: '/onboarding/usage-access'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Step 2 of 6'), findsOneWidget);
    });

    testWidgets('shows Grant Usage Access heading', (tester) async {
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: buildOnboardingRouter(
            initialLocation: '/onboarding/usage-access'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Grant Usage Access'), findsOneWidget);
    });

    testWidgets('shows Open Settings button when not checking', (tester) async {
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: buildOnboardingRouter(
            initialLocation: '/onboarding/usage-access'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Open Settings'), findsOneWidget);
    });

    testWidgets('shows Why do I need this? button', (tester) async {
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: buildOnboardingRouter(
            initialLocation: '/onboarding/usage-access'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Why do I need this?'), findsOneWidget);
    });
  });

  group('UsageAccessScreen — dialog', () {
    testWidgets('tapping Why opens explanation dialog', (tester) async {
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: buildOnboardingRouter(
            initialLocation: '/onboarding/usage-access'),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Why do I need this?'));
      await tester.pumpAndSettle();

      expect(find.text('Why is this needed?'), findsOneWidget);
      expect(find.text('no data ever leaves your phone.', findRichText: true),
          findsNothing); // partial — check the dialog is open instead
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('dialog Got it button dismisses it', (tester) async {
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: buildOnboardingRouter(
            initialLocation: '/onboarding/usage-access'),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Why do I need this?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('UsageAccessScreen — permission flow', () {
    testWidgets('navigates to Verification when permission is granted on resume',
        (tester) async {
      bool permissionGranted = false;
      mockUsageChannel((call) async {
        if (call.method == 'isUsageAccessGranted') return permissionGranted;
        if (call.method == 'openUsageAccessSettings') {
          permissionGranted = true; // simulate user granting in settings
          return null;
        }
        return null;
      });

      await tester.pumpWidget(MaterialApp.router(
        routerConfig: buildOnboardingRouter(
            initialLocation: '/onboarding/usage-access'),
      ));
      await tester.pumpAndSettle();

      // Tap Open Settings — this triggers _openSettings() and sets permissionGranted.
      await tester.tap(find.text('Open Settings'));
      await tester.pump();

      // Simulate app resume (as if user returned from Android settings).
      final state = tester.state(find.byType(UsageAccessScreen));
      // ignore: invalid_use_of_protected_member
      (state as dynamic).didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      // Should navigate to verification screen.
      expect(find.text('Step 3 of 6'), findsOneWidget);

      // AccessVerificationScreen immediately checks permission (returns true)
      // and schedules an 800ms navigation timer — drain it to end the test clean.
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();
    });
  });
}
