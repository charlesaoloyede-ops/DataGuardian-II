import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Session-scoped dismissal per nudge id. Resets on cold start, so a nudge
/// returns until the user actually converts (sets a budget / a limit).
final nudgeDismissedProvider = StateProvider.family<bool, String>((_, __) => false);

/// A clean, dismissible callout prompting the user toward a conversion action
/// (set an app budget, set data limits, …). Presentation-only — the caller
/// decides whether the user has converted and only renders this when they
/// haven't. Hides itself once dismissed this session.
class NudgeBanner extends ConsumerWidget {
  /// Distinct id so each nudge dismisses independently.
  final String id;
  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const NudgeBanner({
    super.key,
    required this.id,
    required this.title,
    required this.message,
    this.icon = Icons.savings_rounded,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(nudgeDismissedProvider(id))) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: scheme.onPrimaryContainer, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: scheme.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onPrimaryContainer,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, size: 18, color: scheme.onPrimaryContainer),
                visualDensity: VisualDensity.compact,
                tooltip: 'Dismiss',
                onPressed: () =>
                    ref.read(nudgeDismissedProvider(id).notifier).state = true,
              ),
            ],
          ),
          if (actionLabel != null && onAction != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: scheme.onPrimaryContainer,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(actionLabel!),
              ),
            ),
        ],
      ),
    );
  }
}
