import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/purchase.dart';
import '../format.dart';
import '../providers/topup_providers.dart';
import 'purchase_status_screen.dart';

class PurchaseHistoryScreen extends ConsumerWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(purchaseHistoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Purchase history')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text('Couldn\'t load your history. Check your connection.',
                textAlign: TextAlign.center),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No purchases yet. Your airtime and data top-ups will show up here.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) => _HistoryTile(purchase: items[i]),
          );
        },
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final Purchase purchase;
  const _HistoryTile({required this.purchase});

  (String, Color) _status(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (purchase.status) {
      case PurchaseStatus.delivered:
        return ('Delivered', Colors.green);
      case PurchaseStatus.refunded:
        return ('Refunded', Colors.orange);
      case PurchaseStatus.failed:
        return ('Failed', scheme.error);
      case PurchaseStatus.paid:
        return ('Delivering', scheme.tertiary);
      case PurchaseStatus.initiated:
        return ('Pending', scheme.outline);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (label, color) = _status(context);
    return ListTile(
      leading: CircleAvatar(
        child: Icon(purchase.type.name == 'data'
            ? Icons.wifi_rounded
            : Icons.phone_android_rounded),
      ),
      title: Text('${purchase.itemLabel} · ${purchase.phone}'),
      subtitle: Text(
          '${purchase.network?.label ?? ''} · ${_date(purchase.createdAt)}'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(naira(purchase.amount),
              style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PurchaseStatusScreen(reference: purchase.reference),
      )),
    );
  }

  String _date(DateTime d) {
    final l = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${l.year}-${two(l.month)}-${two(l.day)} ${two(l.hour)}:${two(l.minute)}';
  }
}
