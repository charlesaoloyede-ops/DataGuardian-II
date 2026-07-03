import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/constants/hive_type_ids.dart';
import 'alert_type.dart';

part 'alert_record.freezed.dart';
part 'alert_record.g.dart';

@freezed
@HiveType(typeId: HiveTypeIds.alertRecord)
class AlertRecord with _$AlertRecord {
  const factory AlertRecord({
    @HiveField(0) required String id,
    @HiveField(1) required AlertType type,
    @HiveField(2) required DateTime triggeredAt,
    @HiveField(3) required String message,
    @HiveField(4) @Default(false) bool isRead,
    /// JSON-encoded metadata string to avoid Hive `Map<String,dynamic>` type issues.
    @HiveField(5) @Default('{}') String metadataJson,
  }) = _AlertRecord;
}
