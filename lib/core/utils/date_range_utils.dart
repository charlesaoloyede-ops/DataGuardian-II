import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../extensions/date_time_extensions.dart';

enum DateFilterPreset { today, last7Days, billingCycle, custom }

class DateRangeFilter {
  final DateTime start;
  final DateTime end;
  final DateFilterPreset preset;

  const DateRangeFilter({
    required this.start,
    required this.end,
    this.preset = DateFilterPreset.custom,
  });

  factory DateRangeFilter.today() {
    final now = DateTime.now();
    return DateRangeFilter(
      start: now.startOfDay,
      end: now,
      preset: DateFilterPreset.today,
    );
  }

  factory DateRangeFilter.last7Days() {
    final now = DateTime.now();
    return DateRangeFilter(
      start: now.subtract(const Duration(days: 6)).startOfDay,
      end: now,
      preset: DateFilterPreset.last7Days,
    );
  }

  factory DateRangeFilter.billingCycle(int? startDay) {
    final now = DateTime.now();
    if (startDay == null || startDay < 1 || startDay > 28) {
      return DateRangeFilter.last30Days();
    }
    final cycleStart = now.day >= startDay
        ? DateTime(now.year, now.month, startDay)
        : DateTime(now.year, now.month - 1, startDay);
    return DateRangeFilter(
      start: cycleStart,
      end: now,
      preset: DateFilterPreset.billingCycle,
    );
  }

  factory DateRangeFilter.last30Days() {
    final now = DateTime.now();
    return DateRangeFilter(
      start: now.subtract(const Duration(days: 29)).startOfDay,
      end: now,
      preset: DateFilterPreset.billingCycle,
    );
  }

  factory DateRangeFilter.fromDateRange(DateTimeRange range) {
    return DateRangeFilter(
      start: range.start.startOfDay,
      end: range.end.endOfDay,
      preset: DateFilterPreset.custom,
    );
  }

  /// Earliest allowed date for custom date picker: 4 months ago.
  static DateTime get earliestAllowed {
    final now = DateTime.now();
    return DateTime(now.year, now.month - AppConstants.maxDateRangeMonths, now.day);
  }

  String get label {
    switch (preset) {
      case DateFilterPreset.today:
        return 'Today';
      case DateFilterPreset.last7Days:
        return '7 Days';
      case DateFilterPreset.billingCycle:
        return 'Billing Cycle';
      case DateFilterPreset.custom:
        final s = '${start.day}/${start.month}/${start.year}';
        final e = '${end.day}/${end.month}/${end.year}';
        return '$s – $e';
    }
  }

  @override
  String toString() => 'DateRangeFilter(${start.dayKey} → ${end.dayKey}, $preset)';
}
