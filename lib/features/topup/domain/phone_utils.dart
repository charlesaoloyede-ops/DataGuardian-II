/// Normalisation and validation for Nigerian mobile numbers.
abstract class PhoneUtils {
  /// Normalises common formats (+234…, 234…, 810…) to a local `0XXXXXXXXXX`.
  static String normalize(String raw) {
    var d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('234')) d = '0${d.substring(3)}';
    if (d.length == 10 && !d.startsWith('0')) d = '0$d';
    return d;
  }

  /// A valid NG mobile number: 11 digits starting with 0 (e.g. 0803…).
  static bool isValid(String raw) {
    final d = normalize(raw);
    return RegExp(r'^0\d{10}$').hasMatch(d);
  }
}
