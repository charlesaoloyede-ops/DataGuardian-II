import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_names.dart';

/// Landing screen for the Top Up tab: tap Airtime or Data to start that flow.
class TopUpHubScreen extends StatelessWidget {
  const TopUpHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Up'),
        actions: [
          IconButton(
            tooltip: 'Purchase history',
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => context.pushNamed(RouteNames.topUpHistory),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _OptionCard(
              icon: Icons.phone_android_rounded,
              title: 'Buy Airtime',
              subtitle: 'Recharge any number instantly',
              onTap: () => context.pushNamed(RouteNames.buyAirtime),
            ),
            const SizedBox(height: 16),
            _OptionCard(
              icon: Icons.wifi_rounded,
              title: 'Buy Data',
              subtitle: 'Pick a data bundle for any network',
              onTap: () => context.pushNamed(RouteNames.buyData),
            ),
            const Spacer(),
            Center(
              child: TextButton.icon(
                onPressed: () => context.pushNamed(RouteNames.topUpHistory),
                icon: const Icon(Icons.history),
                label: const Text('View purchase history'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: scheme.primaryContainer,
                child: Icon(icon, color: scheme.onPrimaryContainer, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
