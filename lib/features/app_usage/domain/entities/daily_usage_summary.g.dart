// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_usage_summary.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyUsageSummaryAdapter extends TypeAdapter<DailyUsageSummary> {
  @override
  final int typeId = 1;

  @override
  DailyUsageSummary read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyUsageSummary(
      date: fields[0] as DateTime,
      totalMobileBytes: fields[1] as int,
      mobileForegroundBytes: fields[2] as int,
      mobileBackgroundBytes: fields[3] as int,
      totalWifiBytes: fields[4] as int,
      isAnomaly: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, DailyUsageSummary obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.totalMobileBytes)
      ..writeByte(2)
      ..write(obj.mobileForegroundBytes)
      ..writeByte(3)
      ..write(obj.mobileBackgroundBytes)
      ..writeByte(4)
      ..write(obj.totalWifiBytes)
      ..writeByte(5)
      ..write(obj.isAnomaly);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyUsageSummaryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
