/// Pure helpers for turning a data plan's advertised name into the numbers the
/// bundle monitor needs (size in bytes, validity in days), plus GB↔bytes for the
/// self-report form. Decimal units (1 GB = 1e9 B) to match [IntX.formattedBytes].
library;

const int bytesPerGb = 1000 * 1000 * 1000;
const int bytesPerMb = 1000 * 1000;

/// Validity in days derived from a plan name's advertised period, mirroring the
/// Daily / Weekly / Monthly grouping on the buy-data screen. Returns null when
/// the name advertises no recognizable period.
int? validityDaysFromName(String name) {
  final n = name.toLowerCase();
  final hr = RegExp(r'(\d+)\s*(hr|hrs|hour|hours)').firstMatch(n);
  final day = RegExp(r'(\d+)\s*(day|days)').firstMatch(n);
  final week = RegExp(r'(\d+)\s*(week|weeks|wks)').firstMatch(n);
  final month = RegExp(r'(\d+)\s*(month|months|mth|mths)').firstMatch(n);
  final year = RegExp(r'(\d+)\s*(year|years|yr|yrs)').firstMatch(n);
  if (hr != null) return 1;
  if (day != null) return int.tryParse(day.group(1)!);
  if (week != null) return int.parse(week.group(1)!) * 7;
  if (month != null) return int.parse(month.group(1)!) * 30;
  if (year != null) return int.parse(year.group(1)!) * 365;
  if (n.contains('daily')) return 1;
  if (n.contains('weekly')) return 7;
  if (n.contains('monthly')) return 30;
  if (n.contains('annual') || n.contains('yearly')) return 365;
  return null;
}

/// Data size in bytes parsed from a plan name (e.g. "1.5GB - 30 days" → 1.5e9).
/// Returns null when no size is advertised.
int? sizeBytesFromName(String name) {
  final m = RegExp(r'(\d+(?:\.\d+)?)\s*(gb|mb)', caseSensitive: false)
      .firstMatch(name);
  if (m == null) return null;
  final value = double.tryParse(m.group(1)!);
  if (value == null) return null;
  final unit = m.group(2)!.toLowerCase();
  return (value * (unit == 'gb' ? bytesPerGb : bytesPerMb)).round();
}
