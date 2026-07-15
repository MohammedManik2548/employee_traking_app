import 'package:hive/hive.dart';

part 'location_payload.g.dart';

@HiveType(typeId: 0)
class LocationPayload {
  @HiveField(0)
  final String employeeId;

  @HiveField(1)
  final double latitude;

  @HiveField(2)
  final double longitude;

  @HiveField(3)
  final double speed;

  @HiveField(4)
  final String timestamp;

  LocationPayload({
    required this.employeeId,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'employee_id': employeeId,
    'latitude': latitude,
    'longitude': longitude,
    'speed': speed,
    'timestamp': timestamp,
  };

  factory LocationPayload.fromJson(Map<String, dynamic> json) {
    return LocationPayload(
      employeeId: json['employee_id'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      speed: (json['speed'] as num).toDouble(),
      timestamp: json['timestamp'] as String,
    );
  }
}