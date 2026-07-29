/// Business rules for the Top Up feature, kept in one place.
abstract class TopUpConstants {
  /// Preset airtime amounts (NGN) shown as quick-select chips.
  static const List<int> airtimePresets = [500, 1000, 1500, 2000, 3000, 5000];

  /// Custom airtime bounds (NGN). Matches the backend Worker's validation.
  static const int minAmount = 100;
  static const int maxAmount = 50000;

  /// How many recent beneficiaries to keep.
  static const int maxBeneficiaries = 12;

  /// Callback path the Paystack checkout redirects to; the webview closes on it.
  static const String paystackCallbackPath = '/paystack/callback';
}
