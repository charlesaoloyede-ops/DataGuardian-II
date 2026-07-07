import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:data_guardian/core/constants/app_constants.dart';
import 'package:data_guardian/core/constants/route_names.dart';
import 'package:data_guardian/core/theme/app_theme.dart';
import 'package:data_guardian/features/onboarding/presentation/screens/access_verification_screen.dart';
import 'package:data_guardian/features/onboarding/presentation/screens/billing_cycle_screen.dart';
import 'package:data_guardian/features/onboarding/presentation/screens/notification_permission_screen.dart';
import 'package:data_guardian/features/onboarding/presentation/screens/onboarding_complete_screen.dart';
import 'package:data_guardian/features/onboarding/presentation/screens/usage_access_screen.dart';
import 'package:data_guardian/features/onboarding/presentation/screens/welcome_screen.dart';

// ── channel constants ─────────────────────────────────────────────────────────

const usageChannel = MethodChannel(AppConstants.usageStatsChannel);
const permissionChannel =
    MethodChannel('flutter.baseflow.com/permissions/methods');

// ── mock channel helpers ───────────────────────────────────────────────────────

void mockUsageChannel(Future<Object?> Function(MethodCall) handler) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(usageChannel, handler);
}

void mockPermissionChannel(Future<Object?> Function(MethodCall) handler) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(permissionChannel, handler);
}

void clearUsageChannel() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(usageChannel, null);
}

void clearPermissionChannel() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(permissionChannel, null);
}

// ── router builder ────────────────────────────────────────────────────────────

/// Builds a minimal GoRouter covering all onboarding routes.
/// Stub destination widgets are used for routes outside the screen under test
/// so navigation assertions can be made by checking for sentinel text.
GoRouter buildOnboardingRouter({
  String initialLocation = '/onboarding',
}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/onboarding',
        name: RouteNames.onboardingWelcome,
        builder: (_, __) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/onboarding/usage-access',
        name: RouteNames.onboardingUsageAccess,
        builder: (_, __) => const UsageAccessScreen(),
      ),
      GoRoute(
        path: '/onboarding/verification',
        name: RouteNames.onboardingVerification,
        builder: (_, __) => const AccessVerificationScreen(),
      ),
      GoRoute(
        path: '/onboarding/notifications',
        name: RouteNames.onboardingNotification,
        builder: (_, __) => const NotificationPermissionScreen(),
      ),
      GoRoute(
        path: '/onboarding/billing-cycle',
        name: RouteNames.onboardingBillingCycle,
        builder: (_, __) => const BillingCycleScreen(),
      ),
      GoRoute(
        path: '/onboarding/complete',
        name: RouteNames.onboardingComplete,
        builder: (_, __) => const OnboardingCompleteScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        name: RouteNames.dashboard,
        builder: (_, __) =>
            const Scaffold(body: Center(child: Text('Dashboard'))),
      ),
    ],
  );
}

/// Wraps [child] in a [MaterialApp] wired with a one-route GoRouter.
Widget buildStandaloneScreen(Widget screen, {String path = '/test'}) {
  final router = GoRouter(
    initialLocation: path,
    routes: [
      GoRoute(path: path, builder: (_, __) => screen),
    ],
  );
  return MaterialApp.router(
    routerConfig: router,
    theme: AppTheme.light(),
  );
}

/// Wraps [app] in the project theme.
Widget withTheme(Widget child) => MaterialApp(
      theme: AppTheme.light(),
      home: child,
    );
