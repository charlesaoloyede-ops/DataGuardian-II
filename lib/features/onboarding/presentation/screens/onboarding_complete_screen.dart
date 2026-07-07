import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/di/injection.dart';
import '../../../../services/background/i_background_service_manager.dart';
import '../../../../services/storage/shared_prefs_service.dart';

class OnboardingCompleteScreen extends StatelessWidget {
  const OnboardingCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Icon(Icons.check_circle_rounded, size: 80, color: scheme.primary),
              const SizedBox(height: 24),
              Text(
                'You\'re all set!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Data Guardian is ready to monitor your usage and send you alerts.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              FilledButton(
                onPressed: () async {
                  await getIt<SharedPrefsService>().setOnboardingComplete(true);
                  final manager = getIt<IBackgroundServiceManager>();
                  await manager.startService();
                  // Ask to be exempted from battery optimization so the monitor
                  // keeps running when the app is closed. Skip if already exempt.
                  if (!await manager.isIgnoringBatteryOptimizations()) {
                    await manager.requestIgnoreBatteryOptimizations();
                  }
                  if (context.mounted) context.goNamed(RouteNames.dashboard);
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text('Go to Dashboard'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
