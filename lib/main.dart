import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'services/background/i_background_service_manager.dart';
import 'services/notification/i_notification_service.dart';
import 'services/storage/hive_service.dart';
import 'services/storage/shared_prefs_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  await configureDependencies();

  // Initialise notification channels (idempotent).
  await getIt<INotificationService>().initialize();

  // Resolve async singletons before use.
  final prefs = await getIt.getAsync<SharedPrefsService>();

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
