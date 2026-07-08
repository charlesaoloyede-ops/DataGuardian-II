import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/analytics/i_analytics_service.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'services/background/i_background_service_manager.dart';
import 'services/notification/i_notification_service.dart';
import 'services/storage/hive_service.dart';
import 'services/storage/shared_prefs_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await HiveService.init();
  await configureDependencies();

  // Initialise notification channels (idempotent).
  await getIt<INotificationService>().initialize();

  // Resolve async singletons before use.
  final prefs = await getIt.getAsync<SharedPrefsService>();

  // Apply the analytics opt-in (default off → no collection until opted in).
  await getIt<IAnalyticsService>()
      .setEnabled(prefs.getPreferences().shareAnonymousAnalytics);

  // Invisible anonymous auth so feedback can be tied to an install without any
  // sign-in or PII. Best-effort — if offline, the feedback repo retries lazily.
  try {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance
          .signInAnonymously()
          .timeout(const Duration(seconds: 5));
    }
  } catch (_) {/* offline; will retry on first submit */}

  // Start background polling when onboarding is already complete.
  if (prefs.onboardingComplete) {
    await getIt<IBackgroundServiceManager>().startService();
  }

  runApp(const ProviderScope(child: DataGuardianApp()));
}

class DataGuardianApp extends ConsumerWidget {
  const DataGuardianApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs  = getIt<SharedPrefsService>();
    final router = buildRouter(onboardingComplete: prefs.onboardingComplete);
    return MaterialApp.router(
      title: 'Data Guardian',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: prefs.isDarkMode ? ThemeMode.dark : ThemeMode.system,
      routerConfig: router,
    );
  }
}
