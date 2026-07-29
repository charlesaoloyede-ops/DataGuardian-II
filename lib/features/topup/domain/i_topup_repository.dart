import 'entities/data_plan.dart';
import 'entities/initiate_result.dart';
import 'entities/network_provider.dart';
import 'entities/purchase.dart';
import 'entities/purchase_type.dart';

/// Contract for the Top Up backend. Writes/actions go through the Cloudflare
/// Worker (which holds the payment/VTU secrets); live reads come from Firestore.
abstract class ITopUpRepository {
  /// Live data bundles for a network (prices are server-authoritative).
  Future<List<DataPlan>> getDataPlans(NetworkProvider network);

  /// Starts a purchase and returns the Paystack checkout URL + reference.
  /// For airtime pass [amount]; for data pass [variationCode].
  Future<InitiateResult> initiate({
    required PurchaseType type,
    required NetworkProvider network,
    required String phone,
    int? amount,
    String? variationCode,
  });

  /// Streams a single transaction as its status changes (initiated → delivered
  /// / refunded), backed by the Firestore document for [reference].
  Stream<Purchase> watchPurchase(String reference);

  /// Streams the current user's purchase history, newest first.
  Stream<List<Purchase>> watchHistory();
}
