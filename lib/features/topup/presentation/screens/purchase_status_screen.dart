import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/entities/purchase_type.dart';
import '../format.dart';
import '../providers/topup_providers.dart';
import '../../../bundle/domain/bundle_math.dart';
import '../../../bundle/presentation/providers/bundle_providers.dart';

/// Watches a transaction to completion: payment → delivery, or refund/failure.
class PurchaseStatusScreen extends ConsumerWidget {
  final String reference;
  const PurchaseStatusScreen({super.key, required this.reference});

  /// When a data purchase is delivered, fold it into the monitored bundle: add
  /// the plan's size to the current remaining and set the new expiry (a top-up
  /// re-anchor). Idempotent per reference, and a no-op when the plan advertises
  /// no parseable size/validity.
  void _reanchorBundleIfDelivered(WidgetRef ref, Purchase p) {
    if (p.status != PurchaseStatus.delivered || p.type != PurchaseType.data) {
      return;
    }
    final name = p.planName;
    if (name == null) return;
    final size = sizeBytesFromName(name);
    final days = validityDaysFromName(name);
    if (size == null || days == null) return;
    ref
        .read(bundleRepositoryProvider)
        .applyTopUp(
          reference: p.reference,
          purchasedSizeBytes: size,
          validityDays: days,
        )
        .then((_) => ref.invalidate(bundleStatusProvider));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(purchaseStatusProvider(reference));

    // Fold a delivered data bundle into monitoring as its status settles.
    ref.listen(purchaseStatusProvider(reference), (_, next) {
      final p = next.valueOrNull;
      if (p != null) _reanchorBundleIfDelivered(ref, p);
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Your purchase')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: async.when(
            loading: () => const _Pending(message: 'Confirming your payment…'),
            error: (_, __) => const _Pending(
              message:
                  'We couldn\'t load the latest status. It will appear in your history shortly.',
              showSpinner: false,
            ),
            data: (p) => _StatusBody(purchase: p),
          ),
        ),
      ),
    );
  }
}

class _StatusBody extends StatelessWidget {
  final Purchase purchase;
  const _StatusBody({required this.purchase});

  @override
  Widget build(BuildContext context) {
    switch (purchase.status) {
      case PurchaseStatus.initiated:
        return const _Pending(message: 'Confirming your payment…');
      case PurchaseStatus.paid:
        return _Pending(message: 'Delivering your ${purchase.itemLabel.toLowerCase()}…');
      case PurchaseStatus.delivered:
        return _Result(
          purchase: purchase,
          icon: Icons.check_circle_rounded,
          color: Colors.green,
          title: 'Delivered!',
          subtitle:
              '${purchase.itemLabel} sent to ${purchase.phone}.',
          showShare: true,
        );
      case PurchaseStatus.refunded:
        return _Result(
          purchase: purchase,
          icon: Icons.replay_circle_filled_rounded,
          color: Colors.orange,
          title: 'Payment refunded',
          subtitle:
              'We couldn\'t deliver this top-up, so your payment was refunded. It may take a little while to reflect.',
        );
      case PurchaseStatus.failed:
        return _Result(
          purchase: purchase,
          icon: Icons.error_rounded,
          color: Theme.of(context).colorScheme.error,
          title: 'Delivery failed',
          subtitle:
              purchase.error ?? 'This purchase could not be completed.',
        );
      case PurchaseStatus.abandoned:
        final reason = purchase.paymentDeclineReason;
        return _Result(
          purchase: purchase,
          icon: Icons.cancel_rounded,
          color: Theme.of(context).colorScheme.error,
          // Show the gateway's own reason when we have one ("Insufficient
          // funds", "Declined"); otherwise a plain not-completed message.
          title: reason != null ? 'Payment failed' : 'Payment not completed',
          subtitle: reason != null
              ? '$reason. You weren\'t charged — please try again.'
              : 'Your payment wasn\'t completed, so this top-up didn\'t go through. You weren\'t charged.',
          // No charge happened, so don't show a big amount that reads like one.
          showAmount: false,
        );
    }
  }
}

class _Pending extends StatelessWidget {
  final String message;
  final bool showSpinner;
  const _Pending({required this.message, this.showSpinner = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showSpinner) const CircularProgressIndicator(),
        const SizedBox(height: 24),
        Text(message, textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Text(
          'You can leave this screen — we\'ll keep processing and it\'ll appear in your history.',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class _Result extends StatelessWidget {
  final Purchase purchase;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool showShare;
  final bool showAmount;
  const _Result({
    required this.purchase,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.showShare = false,
    this.showAmount = true,
  });

  String _receiptText() {
    final p = purchase;
    return [
      'Data Guardian — Top Up receipt',
      '${p.itemLabel}${p.network != null ? ' (${p.network!.label})' : ''}',
      'Recipient: ${p.phone}',
      'Amount: ${naira(p.amount)}',
      'Status: ${p.status.name}',
      'Ref: ${p.reference}',
    ].join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 72),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(subtitle, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        if (showAmount)
          Text(naira(purchase.amount),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 28),
        if (showShare)
          OutlinedButton.icon(
            onPressed: () => Share.share(_receiptText(), subject: 'Top Up receipt'),
            icon: const Icon(Icons.share_outlined),
            label: const Text('Share receipt'),
          ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
