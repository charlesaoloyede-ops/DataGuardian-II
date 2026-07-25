/// Result of starting a purchase: the Paystack checkout URL to open and the
/// reference the app watches for status updates.
class InitiateResult {
  final String reference;
  final String authorizationUrl;
  final int amount; // NGN
  final String? planName;

  const InitiateResult({
    required this.reference,
    required this.authorizationUrl,
    required this.amount,
    this.planName,
  });

  factory InitiateResult.fromJson(Map<String, dynamic> json) => InitiateResult(
        reference: json['reference'] as String,
        authorizationUrl: json['authorizationUrl'] as String,
        amount: (json['amount'] as num).round(),
        planName: json['planName'] as String?,
      );
}
