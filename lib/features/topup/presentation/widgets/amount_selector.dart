import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/topup_constants.dart';

/// Preset airtime amount chips plus a custom-amount field. Reports the resolved
/// amount (or null when the current selection/entry is invalid).
class AmountSelector extends StatefulWidget {
  final ValueChanged<int?> onChanged;
  const AmountSelector({super.key, required this.onChanged});

  @override
  State<AmountSelector> createState() => _AmountSelectorState();
}

class _AmountSelectorState extends State<AmountSelector> {
  int? _preset;
  bool _custom = false;
  final _customCtrl = TextEditingController();
  String? _customError;

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  void _selectPreset(int amount) {
    setState(() {
      _preset = amount;
      _custom = false;
      _customError = null;
    });
    widget.onChanged(amount);
  }

  void _selectCustom() {
    setState(() {
      _custom = true;
      _preset = null;
    });
    _onCustomChanged(_customCtrl.text);
  }

  void _onCustomChanged(String v) {
    final n = int.tryParse(v.trim());
    String? err;
    int? valid;
    if (n == null) {
      err = null; // empty/typing — no error yet, just not valid
    } else if (n < TopUpConstants.minAmount || n > TopUpConstants.maxAmount) {
      err = 'Enter ₦${TopUpConstants.minAmount}–₦${TopUpConstants.maxAmount}.';
    } else {
      valid = n;
    }
    setState(() => _customError = err);
    widget.onChanged(valid);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final amt in TopUpConstants.airtimePresets)
              ChoiceChip(
                label: Text('₦$amt'),
                selected: !_custom && _preset == amt,
                onSelected: (_) => _selectPreset(amt),
              ),
            ChoiceChip(
              label: const Text('Custom'),
              selected: _custom,
              onSelected: (_) => _selectCustom(),
            ),
          ],
        ),
        if (_custom) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _customCtrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            onChanged: _onCustomChanged,
            decoration: InputDecoration(
              labelText: 'Custom amount',
              prefixText: '₦ ',
              errorText: _customError,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ],
    );
  }
}
