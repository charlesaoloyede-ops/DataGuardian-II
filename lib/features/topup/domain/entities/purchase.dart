import 'network_provider.dart';
import 'purchase_type.dart';

/// Lifecycle of a Top Up transaction, mirroring the backend Firestore `status`.
enum PurchaseStatus {
  /// Created; awaiting payment.
  initiated,

  /// Paystack charge confirmed; delivery in progress.
  paid,

  /// VTpass credited the line successfully.
  delivered,

  /// Delivery failed and could not be recovered (usually followed by a refund).
  failed,

  /// Payment was refunded (e.g. delivery failed after a successful charge).
  refunded;

  static PurchaseStatus fromWire(String? s) {
    switch (s) {
      case 'paid':
        return PurchaseStatus.paid;
      case 'delivered':
        return PurchaseStatus.delivered;
      case 'failed':
        return PurchaseStatus.failed;
      case 'refunded':
        return PurchaseStatus.refunded;
      default:
        return PurchaseStatus.initiated;
    }
  }

  bool get isTerminal =>
      this == delivered || this == failed || this == refunded;
}

/// A read model of a Top Up transaction, sourced from Firestore.
class Purchase {
  final String reference;
  final PurchaseType type;
  final NetworkProvider? network;
  final String phone;
  final int amount; // NGN
  final String? planName; // data only
  final PurchaseStatus status;
  final DateTime createdAt;
  final String? error;
  final String? refundReference;

  const Purchase({
    required this.reference,
    required this.type,
    required this.phone,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.network,
    this.planName,
    this.error,
    this.refundReference,
  });

  /// Human-readable description of what was bought.
  String get itemLabel => type == PurchaseType.data
      ? (planName ?? 'Data bundle')
      : 'Airtime';
}
