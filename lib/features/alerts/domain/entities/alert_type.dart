import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/constants/hive_type_ids.dart';

part 'alert_type.g.dart';

@HiveType(typeId: HiveTypeIds.alertType)
enum AlertType {
  @HiveField(0)
  threshold,
  @HiveField(1)
  spike,
  @HiveField(2)
  background,
  @HiveField(3)
  budget,
}
