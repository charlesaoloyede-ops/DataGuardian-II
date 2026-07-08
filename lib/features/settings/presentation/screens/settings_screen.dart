import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../feedback/presentation/providers/feedback_providers.dart';
import '../../../../core/analytics/i_analytics_service.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/di/injection.dart';
import '../../../../services/background/i_background_service_manager.dart';
import '../../../../services/storage/shared_prefs_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int _billingDay;
  late bool _notificationsEnabled;
  late bool _darkMode;
  late bool _shareAnalytics;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final prefs = getIt<SharedPrefsService>().getPreferences();
    _billingDay           = prefs.billingCycleStartDay;
    _notificationsEnabled = prefs.notificationsEnabled;
    _darkMode             = prefs.isDarkMode;
    _shareAnalytics       = prefs.shareAnonymousAnalytics;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final svc  = getIt<SharedPrefsService>();
      final existing = svc.getPreferences();
      await svc.savePreferences(existing.copyWith(
        billingCycleStartDay: _billingDay,
        notificationsEnabled: _notificationsEnabled,
        isDarkMode: _darkMode,
        shareAnonymousAnalytics: _shareAnalytics,
      ));
      await svc.setDarkMode(_darkMode);
      // Apply the opt-in immediately (governs all collection).
      await getIt<IAnalyticsService>().setEnabled(_shareAnalytics);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Appearance ────────────────────────────────────────────────────
          Text('Appearance',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Dark mode'),
            subtitle: const Text('Switch between light and dark theme'),
            value: _darkMode,
            onChanged: (v) => setState(() => _darkMode = v),
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(),
          const SizedBox(height: 8),

          // ── Notifications ─────────────────────────────────────────────────
          Text('Notifications',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Enable notifications'),
            subtitle: const Text('Receive alerts for usage spikes and limits'),
            value: _notificationsEnabled,
            onChanged: (v) => setState(() => _notificationsEnabled = v),
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(),
          const SizedBox(height: 8),

          // ── Background monitoring ─────────────────────────────────────────
          Text('Background monitoring',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          const _BatteryOptimizationTile(),
          const Divider(),
          const SizedBox(height: 8),

          // ── Billing Cycle ─────────────────────────────────────────────────
          Text('Billing cycle',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(
            _billingDay > 0
                ? 'Cycle starts on day $_billingDay of each month.'
                : 'Not set — showing last 30 days on Dashboard.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          _BillingDayPicker(
            selectedDay: _billingDay,
            onChanged: (d) => setState(() => _billingDay = d),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => _billingDay = -1),
            child: const Text('Clear — use last 30 days'),
          ),
          const Divider(),
          const SizedBox(height: 8),

          // ── Privacy ───────────────────────────────────────────────────────
          Text('Privacy',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Share anonymous usage data'),
            subtitle: const Text(
                'Help improve Data Guardian. Never includes your browsing or '
                'which apps you use. Off by default.'),
            value: _shareAnalytics,
            onChanged: (v) => setState(() => _shareAnalytics = v),
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(),
          const SizedBox(height: 8),

          // ── Help & feedback ───────────────────────────────────────────────
          Text('Help & feedback',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.feedback_outlined, color: scheme.primary),
            title: const Text('Send feedback'),
            subtitle: const Text('Report a bug or suggest an improvement'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.pushNamed(RouteNames.feedback),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.forum_outlined, color: scheme.primary),
            title: const Text('Your feedback & replies'),
            subtitle: const Text('See replies from the team'),
            trailing: Consumer(
              builder: (context, ref, _) {
                final unread = ref.watch(unreadReplyCountProvider);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (unread > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: scheme.error,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('$unread',
                            style: TextStyle(
                                color: scheme.onError,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                );
              },
            ),
            onTap: () => context.pushNamed(RouteNames.myFeedback),
          ),
          const Divider(),
          const SizedBox(height: 24),

          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save settings'),
          ),
        ],
      ),
    );
  }
}

/// Shows whether the app is exempt from battery optimization and lets the user
/// grant the exemption — the main lever for keeping the background monitor
/// alive on aggressive OEMs (Samsung, Xiaomi, etc.).
class _BatteryOptimizationTile extends StatefulWidget {
  const _BatteryOptimizationTile();

  @override
  State<_BatteryOptimizationTile> createState() =>
      _BatteryOptimizationTileState();
}

class _BatteryOptimizationTileState extends State<_BatteryOptimizationTile>
    with WidgetsBindingObserver {
  final _manager = getIt<IBackgroundServiceManager>();
  bool? _exempt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check when returning from the system battery-optimization dialog.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final exempt = await _manager.isIgnoringBatteryOptimizations();
    if (mounted) setState(() => _exempt = exempt);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final exempt = _exempt;

    if (exempt == true) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.check_circle_rounded, color: scheme.primary),
        title: const Text('Unrestricted background access'),
        subtitle: const Text(
            'Data Guardian can monitor usage and send alerts reliably.'),
      );
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.battery_alert_rounded, color: scheme.error),
      title: const Text('Allow unrestricted background use'),
      subtitle: const Text(
          'Without this, your device may stop Data Guardian in the background '
          'and alerts can be delayed or missed.'),
      trailing: TextButton(
        onPressed: exempt == null
            ? null
            : () => _manager.requestIgnoreBatteryOptimizations(),
        child: const Text('Allow'),
      ),
    );
  }
}

class _BillingDayPicker extends StatelessWidget {
  final int selectedDay;
  final ValueChanged<int> onChanged;
  const _BillingDayPicker(
      {required this.selectedDay, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: 28,
      itemBuilder: (_, i) {
        final day = i + 1;
        final selected = selectedDay == day;
        return InkWell(
          onTap: () => onChanged(day),
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: selected
                  ? scheme.primary
                  : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
              ),
            ),
          ),
        );
      },
    );
  }
}
