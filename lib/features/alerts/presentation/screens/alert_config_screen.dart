import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../services/storage/shared_prefs_service.dart';

class AlertConfigScreen extends StatefulWidget {
  const AlertConfigScreen({super.key});

  @override
  State<AlertConfigScreen> createState() => _AlertConfigScreenState();
}

class _AlertConfigScreenState extends State<AlertConfigScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _dailyCtrl;
  late TextEditingController _weeklyCtrl;
  late TextEditingController _bgCtrl;
  late double _spikeMultiplier;
  late bool _notificationsEnabled;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final prefs = getIt<SharedPrefsService>().getPreferences();
    _dailyCtrl  = TextEditingController(
        text: _toMb(prefs.dailyThresholdBytes));
    _weeklyCtrl = TextEditingController(
        text: _toMb(prefs.weeklyThresholdBytes));
    _bgCtrl     = TextEditingController(
        text: _toMb(prefs.backgroundThresholdBytes));
    _spikeMultiplier    = prefs.spikeThresholdMultiplier;
    _notificationsEnabled = prefs.notificationsEnabled;
  }

  @override
  void dispose() {
    _dailyCtrl.dispose();
    _weeklyCtrl.dispose();
    _bgCtrl.dispose();
    super.dispose();
  }

  String _toMb(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    return (bytes / (1000 * 1000)).toStringAsFixed(0);
  }

  int? _fromMb(String text) {
    final v = double.tryParse(text.trim());
    if (v == null || v <= 0) return null;
    return (v * 1000 * 1000).toInt();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final svc = getIt<SharedPrefsService>();
      final existing = svc.getPreferences();
      await svc.savePreferences(existing.copyWith(
        dailyThresholdBytes:      _fromMb(_dailyCtrl.text),
        weeklyThresholdBytes:     _fromMb(_weeklyCtrl.text),
        backgroundThresholdBytes: _fromMb(_bgCtrl.text),
        spikeThresholdMultiplier: _spikeMultiplier,
        notificationsEnabled:     _notificationsEnabled,
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved')),
        );
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Alert Settings')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Notifications toggle ───────────────────────────────────────
            SwitchListTile(
              title: const Text('Enable Notifications'),
              subtitle: const Text('Receive alerts on this device'),
              value: _notificationsEnabled,
              onChanged: (v) => setState(() => _notificationsEnabled = v),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            const SizedBox(height: 8),

            // ── Threshold fields ───────────────────────────────────────────
            Text('Data Limits',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text(
              'These limits apply to mobile data only — Wi-Fi usage is never '
              'counted. Leave a field blank to disable that alert. Values in MB.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),

            _ThresholdField(
              controller: _dailyCtrl,
              label: 'Daily mobile limit (MB)',
              icon: Icons.today_rounded,
            ),
            const SizedBox(height: 12),
            _ThresholdField(
              controller: _weeklyCtrl,
              label: 'Weekly mobile limit (MB)',
              icon: Icons.date_range_rounded,
            ),
            const SizedBox(height: 12),
            _ThresholdField(
              controller: _bgCtrl,
              label: 'Background limit per day (MB)',
              icon: Icons.cloud_rounded,
            ),

            const SizedBox(height: 24),

            // ── Spike multiplier ───────────────────────────────────────────
            Text('Spike Sensitivity',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text(
              'Alert when daily usage is ${_spikeMultiplier.toStringAsFixed(1)}× the 7-day average.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            Slider(
              value: _spikeMultiplier,
              min: 1.0,
              max: 3.0,
              divisions: 8,
              label: '${_spikeMultiplier.toStringAsFixed(1)}×',
              onChanged: (v) => setState(() => _spikeMultiplier = v),
            ),

            const SizedBox(height: 32),

            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save Settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThresholdField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  const _ThresholdField(
      {required this.controller,
      required this.label,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return null; // blank = disabled
        final n = double.tryParse(v.trim());
        if (n == null || n <= 0) return 'Enter a positive number';
        return null;
      },
    );
  }
}
