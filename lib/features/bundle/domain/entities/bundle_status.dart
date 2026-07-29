import 'data_bundle.dart';

/// A snapshot of a monitored bundle's health, computed from the [DataBundle]
/// anchor, live device-level consumption, and the rolling daily-usage rate.
/// Mirrors the background monitor's math so the in-app card and the push alerts
/// always tell the same story.
class BundleStatus {
  final DataBundle bundle;

  /// Live remaining bytes (anchor balance − device usage since anchor).
  final int remainingBytes;

  /// Rolling average daily usage (bytes/day), or null when there isn't yet
  /// enough history (<3 days) to project a pace.
  final double? dailyAverageBytes;

  BundleStatus({
    required this.bundle,
    required this.remainingBytes,
    required this.dailyAverageBytes,
  });

  DateTime get expiry => bundle.expiry;

  double get daysUntilExpiry {
    final ms = bundle.expiryMs - DateTime.now().millisecondsSinceEpoch;
    return ms <= 0 ? 0 : ms / Duration.millisecondsPerDay;
  }

  /// Days of data left at the current pace. Null when the pace is unknown.
  double? get runwayDays {
    final avg = dailyAverageBytes;
    if (avg == null || avg <= 0) return null;
    return remainingBytes / avg;
  }

  /// Projected exhaustion date at the current pace, or null when unknown.
  DateTime? get projectedExhaustion {
    final r = runwayDays;
    if (r == null) return null;
    return DateTime.now().add(Duration(milliseconds: (r * Duration.millisecondsPerDay).round()));
  }

  /// Fraction of the nominal size still left (0–1), for the progress bar. Falls
  /// back to the anchor balance when no nominal size was recorded.
  double get fractionRemaining {
    final size = bundle.sizeBytes ?? bundle.anchorBalanceBytes;
    if (size <= 0) return 0;
    return (remainingBytes / size).clamp(0.0, 1.0);
  }

  bool get isExpired => bundle.isExpired;

  /// R2 condition: on pace to run out before expiry.
  bool get isRunningOutEarly {
    final r = runwayDays;
    if (r == null || isExpired || remainingBytes <= 0) return false;
    return r < daysUntilExpiry;
  }

  /// Whole days the bundle is projected to run short (≥1), for copy.
  int get daysShort {
    final r = runwayDays;
    if (r == null) return 0;
    final short = (daysUntilExpiry - r).round();
    return short < 1 ? 1 : short;
  }

  /// R3 condition: down to roughly 3 days of runway.
  bool get isLowRunway {
    final avg = dailyAverageBytes;
    if (avg == null || avg <= 0 || isExpired) return false;
    return remainingBytes <= 3 * avg;
  }
}
