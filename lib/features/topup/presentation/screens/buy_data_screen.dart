import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection.dart';
import '../../../../services/storage/shared_prefs_service.dart';
import '../../domain/entities/data_plan.dart';
import '../../domain/entities/network_provider.dart';
import '../../domain/entities/purchase_type.dart';
import '../../domain/phone_utils.dart';
import '../format.dart';
import '../providers/topup_providers.dart';
import '../topup_flow.dart';
import '../widgets/network_selector.dart';
import '../widgets/recipient_input.dart';

class BuyDataScreen extends ConsumerStatefulWidget {
  const BuyDataScreen({super.key});

  @override
  ConsumerState<BuyDataScreen> createState() => _BuyDataScreenState();
}

class _BuyDataScreenState extends ConsumerState<BuyDataScreen> {
  final _phone = TextEditingController();
  NetworkProvider? _network;
  bool _manualNetwork = false;
  DataPlan? _plan;
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
        setState(() {
          _network = detected;
          _plan = null;
        });
      }
    } else {
      setState(() {});
    }
  }

  bool get _canPay =>
      PhoneUtils.isValid(_phone.text) && _network != null && _plan != null;

  Future<void> _pay() async {
    await runPurchaseFlow(
      context,
      ref,
      type: PurchaseType.data,
      network: _network!,
      phone: PhoneUtils.normalize(_phone.text),
      plan: _plan,
      contactName: _contactName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buy Data')),
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
              _plan = null;
            }),
          ),
          const SizedBox(height: 24),
          Text('Choose a plan', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          if (_network == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('Select a network to see available data plans.'),
            )
          else
            _PlanList(
              network: _network!,
              selected: _plan,
              onSelected: (p) => setState(() => _plan = p),
            ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _canPay ? _pay : null,
            child: Text(_plan == null ? 'Pay' : 'Pay ${naira(_plan!.price)}'),
          ),
        ],
      ),
    );
  }
}

class _PlanList extends ConsumerWidget {
  final NetworkProvider network;
  final DataPlan? selected;
  final ValueChanged<DataPlan> onSelected;
  const _PlanList({
    required this.network,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dataPlansProvider(network));
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            const Expanded(child: Text('Couldn\'t load plans.')),
            TextButton(
              onPressed: () => ref.invalidate(dataPlansProvider(network)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (plans) {
        if (plans.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('No data plans available for this network.'),
          );
        }
        final scheme = Theme.of(context).colorScheme;
        return Column(
          children: [
            for (final p in plans)
              Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: selected?.variationCode == p.variationCode
                    ? scheme.primaryContainer
                    : null,
                child: ListTile(
                  title: Text(p.name),
                  trailing: Text(naira(p.price),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  onTap: () => onSelected(p),
                ),
              ),
          ],
        );
      },
    );
  }
}
