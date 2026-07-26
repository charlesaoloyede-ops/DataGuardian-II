import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Session-scoped dismissal for the budget nudge callout. Resets on cold start,
/// so the nudge returns until the user actually sets a budget (converts).
final budgetNudgeDismissedProvider = StateProvider<bool>((_) => false);

/// A clean, dismissible callout prompting the user to set a per-app data budget.
/// Presentation-only — the caller decides whether the user has converted and
/// only renders this when they haven't. Hides itself once dismissed this session.
class BudgetNudgeBanner extends ConsumerWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const BudgetNudgeBanner({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(budgetNudgeDismissedProvider)) return const SizedBox.shrink();
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
              Icon(Icons.savings_rounded, color: scheme.onPrimaryContainer, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set a data budget',
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
                    ref.read(budgetNudgeDismissedProvider.notifier).state = true,
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
