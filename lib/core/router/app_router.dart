import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/route_names.dart';
import '../widgets/main_scaffold.dart';
import '../../features/onboarding/presentation/screens/welcome_screen.dart';
import '../../features/onboarding/presentation/screens/usage_access_screen.dart';
import '../../features/onboarding/presentation/screens/access_verification_screen.dart';
import '../../features/onboarding/presentation/screens/notification_permission_screen.dart';
import '../../features/onboarding/presentation/screens/billing_cycle_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_complete_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/app_usage/presentation/screens/app_usage_screen.dart';
import '../../features/background_usage/presentation/screens/background_usage_screen.dart';
import '../../features/alerts/presentation/screens/alerts_center_screen.dart';
import '../../features/alerts/presentation/screens/alert_config_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';

GoRouter buildRouter({required bool onboardingComplete}) {
  return GoRouter(
    initialLocation: onboardingComplete ? '/dashboard' : '/onboarding',
    routes: [
      // ── Onboarding (no bottom nav) ─────────────────────────────────────────
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

      // ── Main app shell with bottom nav ────────────────────────────────────
      ShellRoute(
        builder: (_, __, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: RouteNames.dashboard,
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/app-usage',
            name: RouteNames.appUsage,
            builder: (_, __) => const AppUsageScreen(),
          ),
          GoRoute(
            path: '/background-usage',
            name: RouteNames.backgroundUsage,
            builder: (_, __) => const BackgroundUsageScreen(),
          ),
          GoRoute(
            path: '/alerts',
            name: RouteNames.alertsCenter,
            builder: (_, __) => const AlertsCenterScreen(),
          ),
          GoRoute(
            path: '/alerts/config',
            name: RouteNames.alertConfig,
            builder: (_, __) => const AlertConfigScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: RouteNames.settings,
            builder: (_, __) => const SettingsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
  );
}
