import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'helpers/onboarding_test_helpers.dart';

void main() {
  group('WelcomeScreen', () {
    testWidgets('renders app name and tagline', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(routerConfig: buildOnboardingRouter()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Data Guardian'), findsOneWidget);
      expect(find.text('Know where your data goes.'), findsOneWidget);
    });

    testWidgets('renders all four bullet points', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(routerConfig: buildOnboardingRouter()),
      );
      await tester.pumpAndSettle();

      expect(find.text('See exactly which apps use your data'), findsOneWidget);
      expect(find.text('Track both mobile and Wi-Fi usage'), findsOneWidget);
      expect(find.text('Get alerts before you run out'), findsOneWidget);
      expect(find.text('Spot unusual usage spikes early'), findsOneWidget);
    });

    testWidgets('shows Get Started button', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(routerConfig: buildOnboardingRouter()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('tapping Get Started navigates to Usage Access screen',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(routerConfig: buildOnboardingRouter()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // UsageAccessScreen shows Step 2 of 6 in its AppBar.
      expect(find.text('Step 2 of 6'), findsOneWidget);
    });
  });
}
