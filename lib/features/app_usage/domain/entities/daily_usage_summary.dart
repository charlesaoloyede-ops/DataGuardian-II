import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/constants/hive_type_ids.dart';

part 'daily_usage_summary.freezed.dart';
part 'daily_usage_summary.g.dart';

@freezed
@HiveType(typeId: HiveTypeIds.dailyUsageSummary)
class DailyUsageSummary with _$DailyUsageSummary {
  const factory DailyUsageSummary({
    @HiveField(0) required DateTime date,
    @HiveField(1) required int totalMobileBytes,
    @HiveField(2) required int mobileForegroundBytes,
    @HiveField(3) required int mobileBackgroundBytes,
    @HiveField(4) required int totalWifiBytes,
    @HiveField(5) @Default(false) bool isAnomaly,
  }) = _DailyUsageSummary;
}
