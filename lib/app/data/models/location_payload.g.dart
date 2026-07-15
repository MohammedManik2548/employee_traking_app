// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_payload.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocationPayloadAdapter extends TypeAdapter<LocationPayload> {
  @override
  final int typeId = 0;

  @override
  LocationPayload read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocationPayload(
      employeeId: fields[0] as String,
      latitude: fields[1] as double,
      longitude: fields[2] as double,
      speed: fields[3] as double,
      timestamp: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, LocationPayload obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.employeeId)
      ..writeByte(1)
      ..write(obj.latitude)
      ..writeByte(2)
      ..write(obj.longitude)
      ..writeByte(3)
      ..write(obj.speed)
      ..writeByte(4)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationPayloadAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
