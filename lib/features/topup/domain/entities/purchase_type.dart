/// Whether a purchase is variable-amount airtime or a fixed-price data bundle.
enum PurchaseType {
  airtime('airtime', 'Airtime'),
  data('data', 'Data');

  final String wire;
  final String label;
  const PurchaseType(this.wire, this.label);

  static PurchaseType fromWire(String? wire) =>
      wire == 'data' ? PurchaseType.data : PurchaseType.airtime;
}
