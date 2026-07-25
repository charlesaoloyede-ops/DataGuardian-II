import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';
import '../domain/entities/data_plan.dart';
import '../domain/entities/initiate_result.dart';
import '../domain/entities/network_provider.dart';
import '../domain/entities/purchase.dart';
import '../domain/entities/purchase_type.dart';
import '../domain/i_topup_repository.dart';
import 'topup_api_client.dart';

/// Top Up repository.
///
/// Actions that move money (initiate) and product lookups go through the
/// Cloudflare Worker via [TopUpApiClient]. Live status + history are read
/// straight from the user's own Firestore `airtime_transactions` docs — the
/// same anonymous-auth identity pattern as feedback, so the security rules can
/// scope reads to the install.
///
/// Kept dependency-free (constructs its own client, resolves auth lazily) so it
/// remains a synchronous get_it singleton — see the async-DI note in project
/// memory.
@LazySingleton(as: ITopUpRepository)
class TopUpRepository implements ITopUpRepository {
  final TopUpApiClient _api = TopUpApiClient();

  static const _collection = 'airtime_transactions';
  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection(_collection);

  @override
  Future<List<DataPlan>> getDataPlans(NetworkProvider network) =>
      _api.getDataPlans(network);

  @override
  Future<InitiateResult> initiate({
    required PurchaseType type,
    required NetworkProvider network,
    required String phone,
    int? amount,
    String? variationCode,
  }) =>
      _api.initiate(
        type: type,
        network: network,
        phone: phone,
        amount: amount,
        variationCode: variationCode,
      );

  @override
  Stream<Purchase> watchPurchase(String reference) => _col
      .doc(reference)
      .snapshots()
      .where((snap) => snap.exists)
      .map((snap) => _toPurchase(snap.id, snap.data()!));

  @override
  Stream<List<Purchase>> watchHistory() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(const []);
    // Sorted client-side to avoid needing a composite Firestore index.
    return _col.where('uid', isEqualTo: uid).snapshots().map((snap) {
      final list = snap.docs.map((d) => _toPurchase(d.id, d.data())).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Purchase _toPurchase(String id, Map<String, dynamic> d) => Purchase(
        reference: id,
        type: PurchaseType.fromWire(d['type'] as String?),
        network: NetworkProvider.fromWire(d['network'] as String?),
        phone: (d['phone'] as String?) ?? '',
        amount: (d['amount'] as num?)?.round() ?? 0,
        planName: d['planName'] as String?,
        status: PurchaseStatus.fromWire(d['status'] as String?),
        createdAt: _asDate(d['createdAt']) ??
            _asIso(d['clientCreatedAt']) ??
            DateTime.now(),
        error: d['error'] as String?,
        refundReference: d['refundReference'] as String?,
      );

  DateTime? _asDate(dynamic v) => v is Timestamp ? v.toDate() : null;
  DateTime? _asIso(dynamic v) => v is String ? DateTime.tryParse(v) : null;
}
