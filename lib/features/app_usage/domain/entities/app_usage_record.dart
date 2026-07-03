import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/constants/hive_type_ids.dart';

part 'app_usage_record.freezed.dart';
part 'app_usage_record.g.dart';

@freezed
@HiveType(typeId: HiveTypeIds.appUsageRecord)
class AppUsageRecord with _$AppUsageRecord {
  const factory AppUsageRecord({
    @HiveField(0) required String packageName,
    @HiveField(1) required String appName,
    /// Mobile data used in foreground (bytes).
    @HiveField(2) required int mobileForegroundBytes,
    /// Mobile data used in background (bytes).
    @HiveField(3) required int mobileBackgroundBytes,
    /// Wi-Fi data used in foreground (bytes).
    @HiveField(4) required int wifiForegroundBytes,
    /// Wi-Fi data used in background (bytes).
    @HiveField(5) required int wifiBackgroundBytes,
    /// Screen-on time from UsageStatsManager (ms).
    @HiveField(6) required int foregroundTimeMs,
    @HiveField(7) required DateTime periodStart,
    @HiveField(8) required DateTime periodEnd,
    @HiveField(9) String? appIconBase64,
    @HiveField(10) @Default(false) bool isSystemApp,
  }) = _AppUsageRecord;

  const AppUsageRecord._();

  int get totalMobileBytes => mobileForegroundBytes + mobileBackgroundBytes;
  int get totalWifiBytes => wifiForegroundBytes + wifiBackgroundBytes;
  int get totalBytes => totalMobileBytes + totalWifiBytes;
}
