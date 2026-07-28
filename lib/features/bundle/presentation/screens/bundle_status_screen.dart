import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/bundle_math.dart';
import '../providers/bundle_providers.dart';
import '../widgets/bundle_status_card.dart';

/// The full bundle screen (route `/bundle`) — status plus the actions that
/// re-anchor it: correct the balance, top up, edit details, or stop monitoring.
class BundleStatusScreen extends ConsumerWidget {
  const BundleStatusScreen({super.key});

  Future<void> _reSync(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final gb = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update balance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dial your telco\'s balance code, then enter what\'s actually left. This corrects any drift.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Current balance',
                suffixText: 'GB',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, double.tryParse(ctrl.text.trim())),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (gb == null || gb < 0) return;
    await ref.read(bundleRepositoryProvider).reSync((gb * bytesPerGb).round());
    ref.invalidate(bundleStatusProvider);
  }

  Future<void> _stop(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stop monitoring?'),
        content: const Text(
          'We\'ll stop tracking this bundle and its alerts. You can set it up again anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Stop'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(bundleRepositoryProvider).clear();
    ref.invalidate(bundleStatusProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(bundleStatusProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My data bundle')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('Couldn\'t load your bundle.')),
        data: (status) {
          if (status == null) {
            return _EmptyState(onSetUp: () => context.go('/bundle/setup'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(bundleStatusProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                BundleStatusCard(status: status),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _reSync(context, ref),
                        icon: const Icon(Icons.sync_rounded, size: 18),
                        label: const Text('Update balance'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => context.go('/top-up/data'),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Top up'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                TextButton.icon(
                  onPressed: () => context.go('/bundle/setup'),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit bundle details'),
                ),
                TextButton.icon(
                  onPressed: () => _stop(context, ref),
                  icon: Icon(Icons.stop_circle_outlined,
                      size: 18, color: Theme.of(context).colorScheme.error),
                  label: Text('Stop monitoring',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ),
                const SizedBox(height: 16),
                Text(
                  'Balance is estimated from your mobile data usage (hotspot included). For an exact figure, tap Update balance after a USSD check.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onSetUp;
  const _EmptyState({required this.onSetUp});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.data_usage_rounded,
                size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text('Monitor your data bundle',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Get warned before you run out. Works for bundles you bought in the app or elsewhere.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onSetUp,
              child: const Text('Set up monitoring'),
            ),
          ],
        ),
      ),
    );
  }
}
