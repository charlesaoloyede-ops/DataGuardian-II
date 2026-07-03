// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alert_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AlertRecordAdapter extends TypeAdapter<AlertRecord> {
  @override
  final int typeId = 2;

  @override
  AlertRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AlertRecord(
      id: fields[0] as String,
      type: fields[1] as AlertType,
      triggeredAt: fields[2] as DateTime,
      message: fields[3] as String,
      isRead: fields[4] as bool,
      metadataJson: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AlertRecord obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.triggeredAt)
      ..writeByte(3)
      ..write(obj.message)
      ..writeByte(4)
      ..write(obj.isRead)
      ..writeByte(5)
      ..write(obj.metadataJson);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlertRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
