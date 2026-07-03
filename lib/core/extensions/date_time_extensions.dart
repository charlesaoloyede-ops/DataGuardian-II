extension DateTimeX on DateTime {
  DateTime get startOfDay => DateTime(year, month, day);
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  DateTime get startOfMonth => DateTime(year, month, 1);

  DateTime get startOfWeek {
    final diff = weekday - DateTime.monday;
    return subtract(Duration(days: diff)).startOfDay;
  }

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  String get dayKey => '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  String get monthKey => '$year-${month.toString().padLeft(2, '0')}';
}
