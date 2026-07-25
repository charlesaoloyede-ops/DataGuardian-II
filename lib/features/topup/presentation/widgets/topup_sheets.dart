import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/di/injection.dart';
import '../../../../services/security/pin_service.dart';

/// A single label/value row for the confirmation sheet.
typedef ConfirmRow = (String label, String value);

/// Shows a purchase summary and returns true if the user taps the pay button.
Future<bool> showConfirmSheet(
  BuildContext context, {
  required String heading,
  required List<ConfirmRow> rows,
  required String payLabel,
}) async {
  final scheme = Theme.of(context).colorScheme;
  final result = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        top: 4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(heading, style: Theme.of(ctx).textTheme.titleLarge),
          const SizedBox(height: 16),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(r.$1,
                      style: TextStyle(color: scheme.onSurfaceVariant)),
                  Flexible(
                    child: Text(r.$2,
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(payLabel),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  return result ?? false;
}

/// Prompts for the transaction PIN and returns true when it verifies. Returns
/// true immediately if no PIN is set. Returns false if the user cancels.
Future<bool> authorizeWithPin(BuildContext context) async {
  final pin = getIt<PinService>();
  if (!await pin.hasPin()) return true;
  if (!context.mounted) return false;
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _PinSheet(mode: _PinMode.verify),
  );
  return ok ?? false;
}

/// Sets a new transaction PIN. Returns true if a PIN was set.
Future<bool> showPinSetupSheet(BuildContext context) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _PinSheet(mode: _PinMode.setup),
  );
  return ok ?? false;
}

enum _PinMode { verify, setup }

class _PinSheet extends StatefulWidget {
  final _PinMode mode;
  const _PinSheet({required this.mode});

  @override
  State<_PinSheet> createState() => _PinSheetState();
}

class _PinSheetState extends State<_PinSheet> {
  final _pin = TextEditingController();
  final _confirm = TextEditingController();
  final _pinService = getIt<PinService>();
  String? _error;
  bool _busy = false;

  static const _len = 4;

  @override
  void dispose() {
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      if (widget.mode == _PinMode.setup) {
        if (_pin.text.length != _len) {
          setState(() => _error = 'Enter a $_len-digit PIN.');
          return;
        }
        if (_pin.text != _confirm.text) {
          setState(() => _error = 'PINs don\'t match.');
          return;
        }
        await _pinService.setPin(_pin.text);
        if (mounted) Navigator.of(context).pop(true);
      } else {
        final ok = await _pinService.verify(_pin.text);
        if (ok) {
          if (mounted) Navigator.of(context).pop(true);
        } else {
          _pin.clear();
          setState(() => _error = 'Incorrect PIN. Try again.');
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSetup = widget.mode == _PinMode.setup;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isSetup ? 'Set a transaction PIN' : 'Enter your PIN',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            isSetup
                ? 'You\'ll enter this $_len-digit PIN to authorise purchases.'
                : 'Enter your $_len-digit PIN to authorise this purchase.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          _PinField(controller: _pin, label: 'PIN', autofocus: true, maxLen: _len),
          if (isSetup) ...[
            const SizedBox(height: 12),
            _PinField(controller: _confirm, label: 'Confirm PIN', maxLen: _len),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(isSetup ? 'Save PIN' : 'Confirm'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _PinField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool autofocus;
  final int maxLen;
  const _PinField({
    required this.controller,
    required this.label,
    required this.maxLen,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      obscureText: true,
      keyboardType: TextInputType.number,
      maxLength: maxLen,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        border: const OutlineInputBorder(),
      ),
    );
  }
}
