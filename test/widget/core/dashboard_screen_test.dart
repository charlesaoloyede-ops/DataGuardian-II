import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';

import 'package:data_guardian/core/analytics/i_analytics_service.dart';
import 'package:data_guardian/features/app_usage/domain/entities/app_usage_record.dart';
import 'package:data_guardian/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:data_guardian/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:data_guardian/features/dashboard/presentation/screens/dashboard_screen.dart';

// ── mocks ─────────────────────────────────────────────────────────────────────

class MockAnalyticsService extends Mock implements IAnalyticsService {}

// ── helpers ───────────────────────────────────────────────────────────────────

final _now = DateTime(2025, 6, 15);

AppUsageRecord _fakeApp(String name, int mobileBytes) => AppUsageRecord(
      packageName: 'com.$name',
      appName: name,
      mobileForegroundBytes: mobileBytes,
      mobileBackgroundBytes: 0,
      wifiForegroundBytes: 0,
      wifiBackgroundBytes: 0,
      foregroundTimeMs: 0,
      periodStart: _now,
      periodEnd: _now,
    );

DashboardSummary _fakeSummary({
  int usedBytes = 500 * 1000 * 1000,
  int? limitBytes = 2000 * 1000 * 1000,
  bool hasAnomaly = false,
  List<AppUsageRecord>? topApps,
}) =>
    DashboardSummary(
      billingCycleMobileBytes: usedBytes,
      billingCycleMobileLimit: limitBytes,
      last7Days: const [],
      topApps: topApps ?? [_fakeApp('WhatsApp', 200 * 1000 * 1000)],
      allApps: topApps ?? [_fakeApp('WhatsApp', 200 * 1000 * 1000)],
      billingCycleStart: _now,
      hasAnomaly: hasAnomaly,
    );

Widget _buildApp(Override override) {
  return ProviderScope(
    overrides: [override],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/dashboard',
        routes: [
          GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/alerts',    builder: (_, __) => const Scaffold(body: Text('Alerts'))),
          GoRoute(path: '/app-usage', builder: (_, __) => const Scaffold(body: Text('App Usage'))),
        ],
      ),
    ),
  );
}

// ── tests ─────────────────────────────────────────────────────────────────────

void main() {
  late MockAnalyticsService analytics;

  setUp(() {
    analytics = MockAnalyticsService();
    when(() => analytics.logEvent(any(), properties: any(named: 'properties')))
        .thenAnswer((_) async {});
    if (!GetIt.instance.isRegistered<IAnalyticsService>()) {
      GetIt.instance.registerSingleton<IAnalyticsService>(analytics);
    }
  });

  tearDown(() {
    if (GetIt.instance.isRegistered<IAnalyticsService>()) {
      GetIt.instance.unregister<IAnalyticsService>();
    }
  });

  group('DashboardScreen — loading state', () {
    testWidgets('shows CircularProgressIndicator while provider is loading',
        (tester) async {
      final completer = Completer<DashboardSummary>();
      await tester.pumpWidget(
        _buildApp(dashboardSummaryProvider.overrideWith(
          (_) => completer.future,
        )),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Resolve so teardown has no pending futures.
      completer.complete(_fakeSummary());
      await tester.pumpAndSettle();
    });
  });

  group('DashboardScreen — billing cycle card', () {
    testWidgets('shows formatted usage bytes', (tester) async {
      await tester.pumpWidget(
        _buildApp(dashboardSummaryProvider.overrideWith(
          (_) async => _fakeSummary(usedBytes: 500 * 1000 * 1000),
        )),
      );
      await tester.pumpAndSettle();

      // formattedBytes: value=500 >= 100 → 0 decimal places → "500 MB"
      expect(find.text('500 MB'), findsOneWidget);
    });

    testWidgets('shows percentage when limit is set', (tester) async {
      await tester.pumpWidget(
        _buildApp(dashboardSummaryProvider.overrideWith(
          (_) async => _fakeSummary(
            usedBytes: 1500 * 1000 * 1000,
            limitBytes: 2000 * 1000 * 1000,
          ),
        )),
      );
      await tester.pumpAndSettle();

      // "75% used" text is unique to the billing cycle card.
      expect(find.text('75% used'), findsOneWidget);
      expect(find.textContaining('of '), findsOneWidget);
    });

    testWidgets('hides percentage text when no limit configured', (tester) async {
      await tester.pumpWidget(
        _buildApp(dashboardSummaryProvider.overrideWith(
          (_) async => _fakeSummary(limitBytes: null),
        )),
      );
      await tester.pumpAndSettle();

      // No "% used" label when there is no limit.
      expect(find.textContaining('% used'), findsNothing);
    });
  });

  group('DashboardScreen — anomaly banner', () {
    testWidgets('shows anomaly banner when hasAnomaly is true', (tester) async {
      await tester.pumpWidget(
        _buildApp(dashboardSummaryProvider.overrideWith(
          (_) async => _fakeSummary(hasAnomaly: true),
        )),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Unusual data usage detected in the last 7 days.'),
        findsOneWidget,
      );
    });

    testWidgets('hides anomaly banner when hasAnomaly is false', (tester) async {
      await tester.pumpWidget(
        _buildApp(dashboardSummaryProvider.overrideWith(
          (_) async => _fakeSummary(hasAnomaly: false),
        )),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Unusual data usage detected in the last 7 days.'),
        findsNothing,
      );
    });
  });

  group('DashboardScreen — top apps', () {
    testWidgets('shows Top Apps card with app names', (tester) async {
      await tester.pumpWidget(
        _buildApp(dashboardSummaryProvider.overrideWith(
          (_) async => _fakeSummary(topApps: [
            _fakeApp('WhatsApp', 300 * 1000 * 1000),
            _fakeApp('YouTube', 150 * 1000 * 1000),
          ]),
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Top Apps'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);
      expect(find.text('YouTube'), findsOneWidget);
    });

    testWidgets('shows No usage data text when topApps is empty', (tester) async {
      await tester.pumpWidget(
        _buildApp(dashboardSummaryProvider.overrideWith(
          (_) async => _fakeSummary(topApps: []),
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('No usage data yet'), findsOneWidget);
    });
  });

  group('DashboardScreen — error state', () {
    testWidgets('shows permission error state on USAGE_ACCESS_REQUIRED',
        (tester) async {
      await tester.pumpWidget(
        _buildApp(dashboardSummaryProvider.overrideWith(
          (_) async => throw Exception('USAGE_ACCESS_REQUIRED'),
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Usage access permission is required'), findsOneWidget);
      expect(find.text('Go to Settings'), findsOneWidget);
    });

    testWidgets('shows generic error state on unknown error', (tester) async {
      await tester.pumpWidget(
        _buildApp(dashboardSummaryProvider.overrideWith(
          (_) async => throw Exception('Something went wrong'),
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Failed to load data'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
