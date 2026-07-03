// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alert_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AlertTypeAdapter extends TypeAdapter<AlertType> {
  @override
  final int typeId = 3;

  @override
  AlertType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AlertType.threshold;
      case 1:
        return AlertType.spike;
      case 2:
        return AlertType.background;
      default:
        return AlertType.threshold;
    }
  }

  @override
  void write(BinaryWriter writer, AlertType obj) {
    switch (obj) {
      case AlertType.threshold:
        writer.writeByte(0);
        break;
      case AlertType.spike:
        writer.writeByte(1);
        break;
      case AlertType.background:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlertTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
