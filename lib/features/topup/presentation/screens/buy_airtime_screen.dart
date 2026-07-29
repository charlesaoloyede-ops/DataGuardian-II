import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection.dart';
import '../../../../services/storage/shared_prefs_service.dart';
import '../../domain/entities/network_provider.dart';
import '../../domain/entities/purchase_type.dart';
import '../../domain/phone_utils.dart';
import '../topup_flow.dart';
import '../widgets/amount_selector.dart';
import '../widgets/network_selector.dart';
import '../widgets/recipient_input.dart';

class BuyAirtimeScreen extends ConsumerStatefulWidget {
  const BuyAirtimeScreen({super.key});

  @override
  ConsumerState<BuyAirtimeScreen> createState() => _BuyAirtimeScreenState();
}

class _BuyAirtimeScreenState extends ConsumerState<BuyAirtimeScreen> {
  final _phone = TextEditingController();
  NetworkProvider? _network;
  bool _manualNetwork = false;
  int? _amount;
  String? _contactName;

  @override
  void initState() {
    super.initState();
    final prefill = getIt<SharedPrefsService>().defaultRecipientPhone;
    if (prefill != null) {
      _phone.text = prefill;
      _network = NetworkProvider.detectFromPhone(prefill);
    }
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  void _onPhoneChanged(String v) {
    if (!_manualNetwork) {
      final detected = NetworkProvider.detectFromPhone(v);
      if (detected != null && detected != _network) {
        setState(() => _network = detected);
      }
    } else {
      setState(() {});
    }
  }

  bool get _canPay =>
      PhoneUtils.isValid(_phone.text) && _network != null && _amount != null;

  Future<void> _pay() async {
    await runPurchaseFlow(
      context,
      ref,
      type: PurchaseType.airtime,
      network: _network!,
      phone: PhoneUtils.normalize(_phone.text),
      amount: _amount,
      contactName: _contactName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buy Airtime')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          RecipientInput(
            controller: _phone,
            onChanged: _onPhoneChanged,
            onName: (name) => _contactName = name,
          ),
          const SizedBox(height: 24),
          Text('Network', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          NetworkSelector(
            selected: _network,
            onChanged: (n) => setState(() {
              _network = n;
              _manualNetwork = true;
            }),
          ),
          const SizedBox(height: 24),
          Text('Amount', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          AmountSelector(onChanged: (a) => setState(() => _amount = a)),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _canPay ? _pay : null,
            child: Text(_amount == null ? 'Pay' : 'Pay ₦$_amount'),
          ),
        ],
      ),
    );
  }
}
