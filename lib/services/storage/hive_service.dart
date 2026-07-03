import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/hive_type_ids.dart';
import '../../features/app_usage/domain/entities/app_usage_record.dart';
import '../../features/app_usage/domain/entities/daily_usage_summary.dart';
import '../../features/alerts/domain/entities/alert_record.dart';
import '../../features/alerts/domain/entities/alert_type.dart';

/// Initialises Hive and registers all type adapters.
/// Call [init] once from main() before runApp.
@singleton
class HiveService {
  static Future<void> init() async {
    await Hive.initFlutter();
    _registerAdapters();
    await _openBoxes();
  }

  static void _registerAdapters() {
    Hive.registerAdapter(DateTimeAdapter());
    Hive.registerAdapter(AppUsageRecordAdapter());
    Hive.registerAdapter(DailyUsageSummaryAdapter());
    Hive.registerAdapter(AlertTypeAdapter());
    Hive.registerAdapter(AlertRecordAdapter());
  }

  static Future<void> _openBoxes() async {
    await Future.wait([
      Hive.openBox<AppUsageRecord>(AppConstants.appUsageBox),
      Hive.openBox<DailyUsageSummary>(AppConstants.dailyUsageBox),
      Hive.openBox<AlertRecord>(AppConstants.alertsBox),
    ]);
  }

  Box<AppUsageRecord> get appUsageBox =>
      Hive.box<AppUsageRecord>(AppConstants.appUsageBox);

  Box<DailyUsageSummary> get dailyUsageBox =>
      Hive.box<DailyUsageSummary>(AppConstants.dailyUsageBox);

  Box<AlertRecord> get alertsBox =>
      Hive.box<AlertRecord>(AppConstants.alertsBox);
}

/// Hive adapter for [DateTime] — stores as milliseconds since epoch.
class DateTimeAdapter extends TypeAdapter<DateTime> {
  @override
  final int typeId = HiveTypeIds.dateTime;

  @override
  DateTime read(BinaryReader reader) =>
      DateTime.fromMillisecondsSinceEpoch(reader.readInt());

  @override
  void write(BinaryWriter writer, DateTime obj) =>
      writer.writeInt(obj.millisecondsSinceEpoch);
}
