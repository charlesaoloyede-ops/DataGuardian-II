/// Formats a NGN integer amount with thousands separators, e.g. 1500 → "₦1,500".
String naira(int amount) {
  final s = amount.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return '${amount < 0 ? '-' : ''}₦$buf';
}
