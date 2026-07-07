import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'helpers/onboarding_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // permission_handler uses this channel for permission requests.
    mockPermissionChannel((call) async {
      // checkPermissionStatus / requestPermissions → return granted (1).
      if (call.method == 'checkPermissionStatus') return 1;
      if (call.method == 'requestPermissions') return {3: 1}; // POST_NOTIFICATIONS granted
      return null;
    });
  });

  tearDown(clearPermissionChannel);

  group('NotificationPermissionScreen — content', () {
    testWidgets('shows step indicator', (tester) async {
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: buildOnboardingRouter(
            initialLocation: '/onboarding/notifications'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Step 5 of 6'), findsOneWidget);
    });

    testWidgets('shows heading and description', (tester) async {
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: buildOnboardingRouter(
            initialLocation: '/onboarding/notifications'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Stay in the loop'), findsOneWidget);
      expect(find.text('Allow Notifications'), findsOneWidget);
    });

    testWidgets('shows Skip button', (tester) async {
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: buildOnboardingRouter(
            initialLocation: '/onboarding/notifications'),
      ));
      await tester.pumpAndSettle();

      expect(find.text("Skip — I'll miss alerts"), findsOneWidget);
    });
  });

  group('NotificationPermissionScreen — navigation', () {
    testWidgets('Allow Notifications navigates to Billing Cycle', (tester) async {
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: buildOnboardingRouter(
            initialLocation: '/onboarding/notifications'),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Allow Notifications'));
      await tester.pumpAndSettle();

      expect(find.text('Step 6 of 6'), findsOneWidget);
    });

    testWidgets('Skip navigates to Billing Cycle without requesting permission',
        (tester) async {
      bool permissionRequested = false;
      mockPermissionChannel((call) async {
        if (call.method == 'requestPermissions') permissionRequested = true;
        return {3: 1};
      });

      await tester.pumpWidget(MaterialApp.router(
        routerConfig: buildOnboardingRouter(
            initialLocation: '/onboarding/notifications'),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text("Skip — I'll miss alerts"));
      await tester.pumpAndSettle();

      expect(permissionRequested, isFalse);
      expect(find.text('Step 6 of 6'), findsOneWidget);
    });
  });
}
