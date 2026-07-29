/// The Nigerian mobile networks Top Up supports. [wire] is the value the
/// backend Worker/VTpass expects; [label] is what the user sees.
enum NetworkProvider {
  mtn('mtn', 'MTN'),
  airtel('airtel', 'Airtel'),
  glo('glo', 'Glo'),
  nineMobile('9mobile', '9mobile');

  final String wire;
  final String label;
  const NetworkProvider(this.wire, this.label);

  static NetworkProvider? fromWire(String? wire) {
    for (final n in values) {
      if (n.wire == wire) return n;
    }
    return null;
  }

  /// Best-effort network detection from a Nigerian MSISDN prefix. Returns null
  /// when the prefix is unknown so the UI falls back to manual selection.
  static NetworkProvider? detectFromPhone(String rawPhone) {
    final digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    // Normalise +234 / 234 to a leading 0.
    String local = digits;
    if (local.startsWith('234')) local = '0${local.substring(3)}';
    if (local.length < 4 || !local.startsWith('0')) return null;
    final prefix = local.substring(0, 4);
    return _prefixMap[prefix];
  }

  static const Map<String, NetworkProvider> _prefixMap = {
    // MTN
    '0803': mtn, '0806': mtn, '0703': mtn, '0706': mtn, '0813': mtn,
    '0816': mtn, '0810': mtn, '0814': mtn, '0903': mtn, '0906': mtn,
    '0913': mtn, '0916': mtn,
    // Airtel
    '0802': airtel, '0808': airtel, '0708': airtel, '0812': airtel,
    '0701': airtel, '0902': airtel, '0901': airtel, '0904': airtel,
    '0907': airtel, '0912': airtel,
    // Glo
    '0805': glo, '0807': glo, '0705': glo, '0815': glo, '0811': glo,
    '0905': glo, '0915': glo,
    // 9mobile
    '0809': nineMobile, '0818': nineMobile, '0817': nineMobile,
    '0909': nineMobile, '0908': nineMobile,
  };
}
