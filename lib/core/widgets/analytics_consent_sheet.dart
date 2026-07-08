import 'package:flutter/material.dart';
import '../analytics/i_analytics_service.dart';
import '../di/injection.dart';
import '../../services/storage/shared_prefs_service.dart';

/// Shows the one-time analytics consent sheet to already-onboarded users, so
/// they can opt in to the new anonymous analytics after updating — without a
/// reinstall. Shown at most once (tracked by `analyticsConsentPrompted`).
///
/// Whichever way the user chooses, we record the choice, apply it immediately
/// (including toggling Firebase collection), and never ask again.
Future<void> showAnalyticsConsentIfNeeded(BuildContext context) async {
  final prefs = getIt<SharedPrefsService>();
  if (!prefs.onboardingComplete) return; // established users only
  if (prefs.analyticsConsentPrompted) return; // ask once
  if (!context.mounted) return;

  final optIn = await showModalBottomSheet<bool>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    builder: (_) => const _AnalyticsConsentSheet(),
  );

  await prefs.setAnalyticsConsentPrompted(true);
  final enabled = optIn ?? false;
  await prefs.savePreferences(
    prefs.getPreferences().copyWith(shareAnonymousAnalytics: enabled),
  );
  await getIt<IAnalyticsService>().setEnabled(enabled);
}

class _AnalyticsConsentSheet extends StatelessWidget {
  const _AnalyticsConsentSheet();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.insights_rounded,
                  color: scheme.onPrimaryContainer, size: 26),
            ),
            const SizedBox(height: 16),
            Text('Help improve Data Guardian',
                style: textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Text(
              'Share anonymous usage data so we can see which features matter and '
              'fix problems faster.',
              style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            _Point(
              icon: Icons.visibility_off_rounded,
              text: 'Never your browsing, the sites you visit, or which apps '
                  'you use.',
            ),
            const SizedBox(height: 8),
            _Point(
              icon: Icons.tune_rounded,
              text: 'You can turn it off anytime in Settings → Privacy.',
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Share anonymous data'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Not now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Point({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: scheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
