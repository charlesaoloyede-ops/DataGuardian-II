// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_usage_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppUsageRecordAdapter extends TypeAdapter<AppUsageRecord> {
  @override
  final int typeId = 0;

  @override
  AppUsageRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppUsageRecord(
      packageName: fields[0] as String,
      appName: fields[1] as String,
      mobileForegroundBytes: fields[2] as int,
      mobileBackgroundBytes: fields[3] as int,
      wifiForegroundBytes: fields[4] as int,
      wifiBackgroundBytes: fields[5] as int,
      foregroundTimeMs: fields[6] as int,
      periodStart: fields[7] as DateTime,
      periodEnd: fields[8] as DateTime,
      appIconBase64: fields[9] as String?,
      isSystemApp: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AppUsageRecord obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.packageName)
      ..writeByte(1)
      ..write(obj.appName)
      ..writeByte(2)
      ..write(obj.mobileForegroundBytes)
      ..writeByte(3)
      ..write(obj.mobileBackgroundBytes)
      ..writeByte(4)
      ..write(obj.wifiForegroundBytes)
      ..writeByte(5)
      ..write(obj.wifiBackgroundBytes)
      ..writeByte(6)
      ..write(obj.foregroundTimeMs)
      ..writeByte(7)
      ..write(obj.periodStart)
      ..writeByte(8)
      ..write(obj.periodEnd)
      ..writeByte(9)
      ..write(obj.appIconBase64)
      ..writeByte(10)
      ..write(obj.isSystemApp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUsageRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
