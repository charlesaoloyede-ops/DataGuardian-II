import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/constants/route_names.dart';

class NotificationPermissionScreen extends StatelessWidget {
  const NotificationPermissionScreen({super.key});

  Future<void> _request(BuildContext context) async {
    await Permission.notification.request();
    if (!context.mounted) return;
    context.goNamed(RouteNames.onboardingBillingCycle);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Step 5 of 6')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Icon(Icons.notifications_active_rounded, size: 64, color: scheme.primary),
            const SizedBox(height: 24),
            Text('Stay in the loop',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text(
              'Allow notifications so Data Guardian can alert you when your data usage is unusually high or nearing your limit.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => _request(context),
              child: const Text('Allow Notifications'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.goNamed(RouteNames.onboardingBillingCycle),
              child: const Text('Skip — I\'ll miss alerts'),
            ),
          ],
        ),
      ),
    );
  }
}
