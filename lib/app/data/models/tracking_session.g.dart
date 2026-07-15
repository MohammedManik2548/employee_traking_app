// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tracking_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TrackingSessionAdapter extends TypeAdapter<TrackingSession> {
  @override
  final int typeId = 2;

  @override
  TrackingSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TrackingSession(
      date: fields[0] as String,
      clockInTime: fields[1] as DateTime,
      clockOutTime: fields[2] as DateTime?,
      totalDistance: fields[3] as double,
      hourlyLogs: (fields[4] as List).cast<HourlyLocationLog>(),
    );
  }

  @override
  void write(BinaryWriter writer, TrackingSession obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.clockInTime)
      ..writeByte(2)
      ..write(obj.clockOutTime)
      ..writeByte(3)
      ..write(obj.totalDistance)
      ..writeByte(4)
      ..write(obj.hourlyLogs);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrackingSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HourlyLocationLogAdapter extends TypeAdapter<HourlyLocationLog> {
  @override
  final int typeId = 3;

  @override
  HourlyLocationLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HourlyLocationLog(
      time: fields[0] as String,
      locationName: fields[1] as String,
      latitude: fields[2] as double,
      longitude: fields[3] as double,
    );
  }

  @override
  void write(BinaryWriter writer, HourlyLocationLog obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.time)
      ..writeByte(1)
      ..write(obj.locationName)
      ..writeByte(2)
      ..write(obj.latitude)
      ..writeByte(3)
      ..write(obj.longitude);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HourlyLocationLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
