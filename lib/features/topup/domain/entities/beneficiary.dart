import 'network_provider.dart';

/// A saved recipient the user can reuse. Created from any number they buy for —
/// whether typed manually or picked from contacts.
class Beneficiary {
  final String phone;
  final NetworkProvider? network;
  final String? name; // optional label, e.g. from a contact
  final DateTime lastUsed;

  const Beneficiary({
    required this.phone,
    required this.lastUsed,
    this.network,
    this.name,
  });

  Beneficiary copyWith({DateTime? lastUsed, String? name, NetworkProvider? network}) =>
      Beneficiary(
        phone: phone,
        lastUsed: lastUsed ?? this.lastUsed,
        name: name ?? this.name,
        network: network ?? this.network,
      );

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'network': network?.wire,
        'name': name,
        'lastUsed': lastUsed.toUtc().toIso8601String(),
      };

  factory Beneficiary.fromJson(Map<String, dynamic> json) => Beneficiary(
        phone: json['phone'] as String,
        network: NetworkProvider.fromWire(json['network'] as String?),
        name: json['name'] as String?,
        lastUsed: DateTime.tryParse(json['lastUsed'] as String? ?? '')?.toLocal() ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}
