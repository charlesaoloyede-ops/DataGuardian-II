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
  final _scroll = ScrollController();
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
    _scroll.dispose();
    super.dispose();
  }

  void _onPlanSelected(DataPlan p) {
    setState(() => _plan = p);
    // Bring the Pay button into view so the next step is obvious.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
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
        controller: _scroll,
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
              onSelected: _onPlanSelected,
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
        // Group into Daily / Weekly / Monthly (+ Other for anything that
        // doesn't advertise a clear validity) for easier discovery.
        final groups = <_PlanBucket, List<DataPlan>>{
          for (final b in _PlanBucket.values) b: [],
        };
        for (final p in plans) {
          groups[_bucketOf(p.name)]!.add(p);
        }

        Widget tile(DataPlan p) => Card(
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
            );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final bucket in _PlanBucket.values)
              if (groups[bucket]!.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Text(
                    bucket.label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                ...groups[bucket]!.map(tile),
              ],
          ],
        );
      },
    );
  }
}

enum _PlanBucket {
  daily('Daily'),
  weekly('Weekly'),
  monthly('Monthly'),
  other('Other plans');

  const _PlanBucket(this.label);
  final String label;
}

/// Buckets a plan by the validity advertised in its name (e.g. "24 hrs",
/// "7 days", "30 days", "Monthly", "1 Year"). Falls back to [other].
_PlanBucket _bucketOf(String name) {
  final n = name.toLowerCase();
  int? days;
  final hr = RegExp(r'(\d+)\s*(hr|hrs|hour|hours)').firstMatch(n);
  final day = RegExp(r'(\d+)\s*(day|days)').firstMatch(n);
  final week = RegExp(r'(\d+)\s*(week|weeks|wks)').firstMatch(n);
  final month = RegExp(r'(\d+)\s*(month|months|mth|mths)').firstMatch(n);
  final year = RegExp(r'(\d+)\s*(year|years|yr|yrs)').firstMatch(n);
  if (hr != null) days = 1;
  if (day != null) days = int.tryParse(day.group(1)!);
  if (week != null) days = int.parse(week.group(1)!) * 7;
  if (month != null) days = int.parse(month.group(1)!) * 30;
  if (year != null) days = int.parse(year.group(1)!) * 365;
  if (days == null) {
    if (n.contains('daily')) {
      days = 1;
    } else if (n.contains('weekly') || n.contains('week')) {
      days = 7;
    } else if (n.contains('monthly') || n.contains('month')) {
      days = 30;
    } else if (n.contains('year') || n.contains('annual')) {
      days = 365;
    }
  }
  if (days == null) return _PlanBucket.other;
  if (days <= 3) return _PlanBucket.daily;
  if (days <= 13) return _PlanBucket.weekly;
  return _PlanBucket.monthly;
}
