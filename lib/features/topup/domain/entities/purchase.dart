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
  refunded,

  /// Payment did not go through — declined, insufficient funds, or the checkout
  /// was never completed. No money was captured. Terminal.
  abandoned;

  static PurchaseStatus fromWire(String? s) {
    switch (s) {
      case 'paid':
      // The provider has the money and is crediting/settling — still, from the
      // user's view, "delivering". Treated like `paid` here.
      case 'crediting':
      case 'processing':
        return PurchaseStatus.paid;
      case 'delivered':
        return PurchaseStatus.delivered;
      case 'failed':
        return PurchaseStatus.failed;
      case 'refunded':
        return PurchaseStatus.refunded;
      case 'abandoned':
        return PurchaseStatus.abandoned;
      default:
        return PurchaseStatus.initiated;
    }
  }

  bool get isTerminal =>
      this == delivered ||
      this == failed ||
      this == refunded ||
      this == abandoned;
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

  /// When a payment did not go through (`abandoned`), the reason to show the
  /// user — the payment gateway's own response for a definite decline
  /// (e.g. "Insufficient funds", "Declined"). Null for a plain not-completed
  /// checkout, where there's no meaningful reason to surface.
  ///
  /// The backend encodes a hard decline as `error: "payment_failed: <reason>"`.
  String? get paymentDeclineReason {
    final e = error;
    if (e == null) return null;
    const prefix = 'payment_failed: ';
    if (!e.startsWith(prefix)) return null;
    final reason = e.substring(prefix.length).trim();
    if (reason.isEmpty || reason.toLowerCase() == 'verify_failed') return null;
    // Gateway responses arrive human-readable; just ensure a leading capital.
    return reason[0].toUpperCase() + reason.substring(1);
  }
}
