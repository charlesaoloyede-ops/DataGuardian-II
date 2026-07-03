import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/route_names.dart';

class AccessVerificationScreen extends StatefulWidget {
  const AccessVerificationScreen({super.key});

  @override
  State<AccessVerificationScreen> createState() => _AccessVerificationScreenState();
}

class _AccessVerificationScreenState extends State<AccessVerificationScreen> {
  static const _channel = MethodChannel(AppConstants.usageStatsChannel);
  bool? _granted;

  @override
  void initState() {
    super.initState();
    _verify();
  }

  Future<void> _verify() async {
    final granted = await _channel.invokeMethod<bool>('isUsageAccessGranted') ?? false;
    if (mounted) setState(() => _granted = granted);
    if (granted) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) context.goNamed(RouteNames.onboardingNotification);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Step 3 of 6')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_granted == null)
                const CircularProgressIndicator()
              else if (_granted!)
                Icon(Icons.check_circle_rounded, size: 72, color: scheme.primary)
              else
                Icon(Icons.cancel_rounded, size: 72, color: scheme.error),
              const SizedBox(height: 24),
              Text(
                _granted == null
                    ? 'Checking permission...'
                    : _granted!
                        ? 'Permission granted!'
                        : 'Permission not granted',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (_granted == false) ...[
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.goNamed(RouteNames.onboardingUsageAccess),
                  child: const Text('Try again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
