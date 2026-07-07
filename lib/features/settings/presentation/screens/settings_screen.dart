import 'package:flutter/material.dart';
import '../../../../core/di/injection.dart';
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

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final prefs = getIt<SharedPrefsService>().getPreferences();
    _billingDay           = prefs.billingCycleStartDay;
    _notificationsEnabled = prefs.notificationsEnabled;
    _darkMode             = prefs.isDarkMode;
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
      ));
      await svc.setDarkMode(_darkMode);
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
