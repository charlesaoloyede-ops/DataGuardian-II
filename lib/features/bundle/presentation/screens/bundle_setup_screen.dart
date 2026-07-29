import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/bundle_math.dart';
import '../providers/bundle_providers.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
String _shortDate(DateTime d) => '${d.day} ${_months[d.month - 1]}';

const Map<int, String> _validityOptions = {
  1: '1 day',
  3: '3 days',
  7: '7 days (weekly)',
  14: '14 days',
  30: '30 days (monthly)',
  60: '60 days',
  90: '90 days',
};

/// R4: self-report a bundle bought outside the app (also used to edit an
/// existing bundle's details). Anchors monitoring on the balance entered here.
class BundleSetupScreen extends ConsumerStatefulWidget {
  const BundleSetupScreen({super.key});

  @override
  ConsumerState<BundleSetupScreen> createState() => _BundleSetupScreenState();
}

class _BundleSetupScreenState extends ConsumerState<BundleSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sizeCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController();
  DateTime _startDate = DateTime.now();
  int _validityDays = 30;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Prefill when editing an existing bundle.
    final b = ref.read(bundleRepositoryProvider).current;
    if (b != null) {
      _startDate = b.anchoredAt;
      if (b.sizeBytes != null) {
        _sizeCtrl.text = (b.sizeBytes! / bytesPerGb).toStringAsFixed(2);
      }
      _balanceCtrl.text = (b.anchorBalanceBytes / bytesPerGb).toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _sizeCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  int? _gbToBytes(String raw) {
    final v = double.tryParse(raw.trim());
    if (v == null) return null;
    return (v * bytesPerGb).round();
  }

  DateTime get _expiry => DateTime(_startDate.year, _startDate.month, _startDate.day)
      .add(Duration(days: _validityDays));

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(now.year, now.month - 4, now.day),
      lastDate: now,
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_expiry.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('This bundle has already expired — nothing to monitor.'),
      ));
      return;
    }
    setState(() => _saving = true);
    final balance = _gbToBytes(_balanceCtrl.text)!;
    final size = _sizeCtrl.text.trim().isEmpty ? null : _gbToBytes(_sizeCtrl.text);
    await ref.read(bundleRepositoryProvider).saveSelfReport(
          startDate: _startDate,
          validityDays: _validityDays,
          currentBalanceBytes: balance,
          sizeBytes: size,
        );
    ref.invalidate(bundleStatusProvider);
    if (mounted) context.go('/bundle');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final editing = ref.read(bundleRepositoryProvider).current != null;

    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Edit bundle' : 'Monitor a bundle')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Enter the details of a bundle you bought elsewhere (USSD, your telco app, or an agent). We\'ll warn you before it runs out.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),

            Text('Purchase / start date', style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${_shortDate(_startDate)} ${_startDate.year}'),
                    const Icon(Icons.calendar_today_outlined, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text('Validity', style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            DropdownButtonFormField<int>(
              initialValue: _validityDays,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              items: _validityOptions.entries
                  .map((e) =>
                      DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _validityDays = v ?? 30),
            ),
            const SizedBox(height: 20),

            Text('Bundle size (optional)', style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            TextFormField(
              controller: _sizeCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'e.g. 15',
                suffixText: 'GB',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null; // optional
                if (_gbToBytes(v) == null) return 'Enter a valid number';
                return null;
              },
            ),
            const SizedBox(height: 20),

            Text('Current balance', style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            TextFormField(
              controller: _balanceCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'From your USSD / telco check',
                suffixText: 'GB',
              ),
              validator: (v) {
                final bytes = v == null ? null : _gbToBytes(v);
                if (bytes == null || bytes <= 0) {
                  return 'Enter your current balance';
                }
                final size = _gbToBytes(_sizeCtrl.text);
                if (size != null && bytes > size) {
                  return 'Balance can\'t be more than the bundle size';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.mobileDataColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 18, color: AppTheme.mobileDataColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'We\'ll track from today and expire this bundle on ${_shortDate(_expiry)}. Re-sync anytime after a USSD check to stay accurate.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppTheme.mobileDataColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            FilledButton(
              onPressed: _saving ? null : _submit,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(_saving
                    ? 'Saving…'
                    : (editing ? 'Save changes' : 'Start monitoring')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
