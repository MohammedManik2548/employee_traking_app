import 'package:hive/hive.dart';

part 'tracking_session.g.dart';

@HiveType(typeId: 2)
class TrackingSession extends HiveObject {
  @HiveField(0)
  final String date;

  @HiveField(1)
  final DateTime clockInTime;

  @HiveField(2)
  DateTime? clockOutTime;

  @HiveField(3)
  final double totalDistance;

  @HiveField(4)
  final List<HourlyLocationLog> hourlyLogs;

  // ADD THIS FIELD TO STORE THE COMPLETE ROUTE PATH COORDS
  @HiveField(5)
  final List<List<double>> routeCoordinates; // Stores raw pairs: [[lat, lng], [lat, lng]]

  TrackingSession({
    required this.date,
    required this.clockInTime,
    this.clockOutTime,
    required this.totalDistance,
    required this.hourlyLogs,
    required this.routeCoordinates,
  });
}

@HiveType(typeId: 3)
class HourlyLocationLog {
  @HiveField(0)
  final String time;

  @HiveField(1)
  final String locationName;

  @HiveField(2)
  final double latitude;

  @HiveField(3)
  final double longitude;

  HourlyLocationLog({
    required this.time,
    required this.locationName,
    required this.latitude,
    required this.longitude,
  });
}