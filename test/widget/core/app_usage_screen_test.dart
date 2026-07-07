import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';

import 'package:data_guardian/core/analytics/i_analytics_service.dart';
import 'package:data_guardian/core/error/exceptions.dart';
import 'package:data_guardian/features/alerts/domain/entities/user_preferences.dart';
import 'package:data_guardian/features/app_usage/domain/entities/app_usage_record.dart';
import 'package:data_guardian/features/app_usage/domain/use_cases/get_app_usage_use_case.dart';
import 'package:data_guardian/features/app_usage/presentation/providers/app_usage_providers.dart';
import 'package:data_guardian/features/app_usage/presentation/screens/app_usage_screen.dart';
import 'package:data_guardian/services/storage/shared_prefs_service.dart';

// ── mocks ─────────────────────────────────────────────────────────────────────

class MockAnalyticsService extends Mock implements IAnalyticsService {}
class MockSharedPrefsService extends Mock implements SharedPrefsService {}

// ── helpers ───────────────────────────────────────────────────────────────────

final _now = DateTime(2025, 6, 15);

AppUsageRecord _fakeApp(
  String name, {
  int mobileFg = 100 * 1000 * 1000,
  bool isSystem = false,
}) =>
    AppUsageRecord(
      packageName: 'com.$name',
      appName: name,
      mobileForegroundBytes: mobileFg,
      mobileBackgroundBytes: 0,
      wifiForegroundBytes: 50 * 1000 * 1000,
      wifiBackgroundBytes: 0,
      foregroundTimeMs: 0,
      periodStart: _now,
      periodEnd: _now,
      isSystemApp: isSystem,
    );

Widget _buildApp({required List<Override> overrides}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/app-usage',
        routes: [
          GoRoute(path: '/app-usage', builder: (_, __) => const AppUsageScreen()),
        ],
      ),
    ),
  );
}

// ── tests ─────────────────────────────────────────────────────────────────────

void main() {
  late MockAnalyticsService analytics;
  late MockSharedPrefsService prefs;

  setUp(() {
    analytics = MockAnalyticsService();
    when(() => analytics.logEvent(any(), properties: any(named: 'properties')))
        .thenAnswer((_) async {});
    if (!GetIt.instance.isRegistered<IAnalyticsService>()) {
      GetIt.instance.registerSingleton<IAnalyticsService>(analytics);
    }

    prefs = MockSharedPrefsService();
    when(() => prefs.getPreferences()).thenReturn(const UserPreferences());
    when(() => prefs.getAppBudgets()).thenReturn({});
    if (!GetIt.instance.isRegistered<SharedPrefsService>()) {
      GetIt.instance.registerSingleton<SharedPrefsService>(prefs);
    }
  });

  tearDown(() {
    if (GetIt.instance.isRegistered<IAnalyticsService>()) {
      GetIt.instance.unregister<IAnalyticsService>();
    }
    if (GetIt.instance.isRegistered<SharedPrefsService>()) {
      GetIt.instance.unregister<SharedPrefsService>();
    }
  });

  group('AppUsageScreen — loading state', () {
    testWidgets('shows CircularProgressIndicator while loading', (tester) async {
      final completer = Completer<List<AppUsageRecord>>();
      await tester.pumpWidget(
        _buildApp(overrides: [
          appUsageListProvider.overrideWith((_) => completer.future),
        ]),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete([]);
      await tester.pumpAndSettle();
    });
  });

  group('AppUsageScreen — app list', () {
    testWidgets('shows Personal Apps section for non-system apps', (tester) async {
      await tester.pumpWidget(
        _buildApp(overrides: [
          appUsageListProvider.overrideWith((_) async => [_fakeApp('WhatsApp')]),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Personal Apps'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);
    });

    testWidgets('shows System Apps section for system apps', (tester) async {
      await tester.pumpWidget(
        _buildApp(overrides: [
          appUsageListProvider.overrideWith(
            (_) async => [_fakeApp('SystemApp', isSystem: true)],
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('System Apps'), findsOneWidget);
      expect(find.text('SystemApp'), findsOneWidget);
    });

    testWidgets('shows both sections when personal and system apps present',
        (tester) async {
      await tester.pumpWidget(
        _buildApp(overrides: [
          appUsageListProvider.overrideWith((_) async => [
            _fakeApp('WhatsApp'),
            _fakeApp('SystemProcess', isSystem: true),
          ]),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Personal Apps'), findsOneWidget);
      expect(find.text('System Apps'), findsOneWidget);
    });
  });

  group('AppUsageScreen — empty state', () {
    testWidgets('shows mobile empty state when provider returns empty list',
        (tester) async {
      await tester.pumpWidget(
        _buildApp(overrides: [
          appUsageListProvider.overrideWith((_) async => []),
          visibleNetworksProvider.overrideWith((_) => {NetworkView.mobile}),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('No mobile usage in the selected period.'), findsOneWidget);
    });
  });

  group('AppUsageScreen — OEM restriction', () {
    testWidgets('shows OEM restriction banner when provider throws exception',
        (tester) async {
      await tester.pumpWidget(
        _buildApp(overrides: [
          appUsageListProvider.overrideWith(
            (_) async => throw const NetworkStatsRestrictedException(),
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Per-app data unavailable'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    });
  });

  group('AppUsageScreen — filter chips', () {
    testWidgets('shows Today, 7 Days, Billing Cycle, and Custom chips',
        (tester) async {
      await tester.pumpWidget(
        _buildApp(overrides: [
          appUsageListProvider.overrideWith((_) async => []),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('7 Days'), findsOneWidget);
      expect(find.text('Billing Cycle'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);
    });

    testWidgets('shows Mobile / Wi-Fi toggle', (tester) async {
      await tester.pumpWidget(
        _buildApp(overrides: [
          appUsageListProvider.overrideWith((_) async => []),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mobile'), findsOneWidget);
      expect(find.text('Wi-Fi'), findsOneWidget);
    });
  });
}
