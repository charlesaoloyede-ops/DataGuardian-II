extension IntX on int {
  /// Total bytes as a human-readable decimal string (KB/MB/GB).
  String get formattedBytes {
    if (this < 1000) return '$this B';
    const units = ['KB', 'MB', 'GB', 'TB'];
    var value = this / 1000.0;
    var unit = 0;
    while (value >= 1000 && unit < units.length - 1) {
      value /= 1000;
      unit++;
    }
    final digits = value >= 100 ? 0 : value >= 10 ? 1 : 2;
    return '${value.toStringAsFixed(digits)} ${units[unit]}';
  }
}
