/// A data bundle offered by a network, fetched live from the backend (prices
/// are authoritative server-side — never trusted from the client).
class DataPlan {
  final String variationCode;
  final String name;
  final int price; // NGN

  const DataPlan({
    required this.variationCode,
    required this.name,
    required this.price,
  });

  factory DataPlan.fromJson(Map<String, dynamic> json) => DataPlan(
        variationCode: json['variationCode'] as String,
        name: json['name'] as String,
        price: (json['price'] as num).round(),
      );
}
