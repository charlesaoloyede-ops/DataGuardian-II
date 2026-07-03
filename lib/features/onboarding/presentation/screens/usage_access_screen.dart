import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/route_names.dart';

class UsageAccessScreen extends StatefulWidget {
  const UsageAccessScreen({super.key});

  @override
  State<UsageAccessScreen> createState() => _UsageAccessScreenState();
}

class _UsageAccessScreenState extends State<UsageAccessScreen> with WidgetsBindingObserver {
  static const _channel = MethodChannel(AppConstants.usageStatsChannel);
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkPermission();
  }

  Future<void> _checkPermission() async {
    setState(() => _checking = true);
    final granted = await _channel.invokeMethod<bool>('isUsageAccessGranted') ?? false;
    if (!mounted) return;
    setState(() => _checking = false);
    if (granted) context.goNamed(RouteNames.onboardingVerification);
  }

  Future<void> _openSettings() async {
    await _channel.invokeMethod('openUsageAccessSettings');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Step 2 of 6')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Icon(Icons.security_rounded, size: 64, color: scheme.primary),
            const SizedBox(height: 24),
            Text('Grant Usage Access',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text(
              'Data Guardian needs Usage Access to see which apps are using your mobile and Wi-Fi data.\n\n'
              'On the next screen, find "Data Guardian" and enable the toggle.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            if (_checking)
              const Center(child: CircularProgressIndicator())
            else
              FilledButton(
                onPressed: _openSettings,
                child: const Text('Open Settings'),
              ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Why is this needed?'),
                  content: const Text(
                    'Android restricts access to per-app data usage for privacy reasons. '
                    'The Usage Access permission lets Data Guardian read this information '
                    'from your device — no data ever leaves your phone.',
                  ),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it'))],
                ),
              ),
              child: const Text('Why do I need this?'),
            ),
          ],
        ),
      ),
    );
  }
}
