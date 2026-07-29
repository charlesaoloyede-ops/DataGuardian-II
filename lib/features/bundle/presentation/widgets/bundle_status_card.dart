import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/bundle_status.dart';
import '../providers/bundle_providers.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _shortDate(DateTime d) => '${d.day} ${_months[d.month - 1]}';

String _expiryLabel(BundleStatus s) {
  final days = s.daysUntilExpiry;
  final when = _shortDate(s.expiry);
  if (days < 1) return 'Expires today · $when';
  final n = days.round();
  return 'Expires in $n ${n == 1 ? 'day' : 'days'} · $when';
}

/// The reusable bundle summary card — remaining, progress bar, and a pace line
/// that flips to an amber warning when the bundle is projected to run out early.
class BundleStatusCard extends StatelessWidget {
  final BundleStatus status;
  const BundleStatusCard({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final atRisk = status.isRunningOutEarly;
    final size = status.bundle.sizeBytes ?? status.bundle.anchorBalanceBytes;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: atRisk
              ? AppTheme.backgroundDataColor.withValues(alpha: 0.5)
              : theme.dividerColor.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('My data bundle',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              Text(_expiryLabel(status),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(status.remainingBytes.formattedBytes,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Text('left of ${size.formattedBytes}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: status.fractionRemaining,
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor:
                  const AlwaysStoppedAnimation(AppTheme.mobileDataColor),
            ),
          ),
          const SizedBox(height: 10),
          _PaceLine(status: status, atRisk: atRisk),
        ],
      ),
    );
  }
}

class _PaceLine extends StatelessWidget {
  final BundleStatus status;
  final bool atRisk;
  const _PaceLine({required this.status, required this.atRisk});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final runway = status.runwayDays;

    late final IconData icon;
    late final Color color;
    late final String text;

    if (runway == null) {
      icon = Icons.hourglass_empty_rounded;
      color = theme.colorScheme.onSurfaceVariant;
      text = 'Learning your usage — projection in a day or two';
    } else if (atRisk) {
      icon = Icons.warning_amber_rounded;
      color = AppTheme.backgroundDataColor;
      final exhaust = status.projectedExhaustion;
      text = 'On pace to run out ~${status.daysShort} '
          '${status.daysShort == 1 ? 'day' : 'days'} early'
          '${exhaust != null ? ' (around ${_shortDate(exhaust)})' : ''}';
    } else {
      icon = Icons.check_circle_outline_rounded;
      color = AppTheme.wifiDataColor;
      final d = runway.round();
      text = "~$d ${d == 1 ? 'day' : 'days'} of data at your pace — you're on track";
    }

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: theme.textTheme.bodySmall?.copyWith(color: color)),
        ),
      ],
    );
  }
}

/// Empty-state prompt shown on Home when no bundle is monitored yet.
class BundleEmptyCard extends StatelessWidget {
  const BundleEmptyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.go('/bundle/setup'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.data_usage_rounded,
                color: AppTheme.mobileDataColor, size: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Monitor your data bundle',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    'Get warned before you run out — even for a bundle you bought elsewhere.',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

/// Home-screen entry point: shows the empty card, or a tappable status card that
/// opens the full bundle screen.
class BundleHomeCard extends ConsumerWidget {
  const BundleHomeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(bundleStatusProvider);
    return async.maybeWhen(
      data: (status) {
        if (status == null) return const BundleEmptyCard();
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.go('/bundle'),
          child: BundleStatusCard(status: status),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
