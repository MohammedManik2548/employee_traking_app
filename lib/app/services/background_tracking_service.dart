import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dio/dio.dart';
import '../data/models/location_payload.dart';
import '../data/models/tracking_session.dart';
import '../data/providers/hive_storage_service.dart';
import '../modules/controllers/tracking_controller.dart';

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      initialNotificationTitle: "Always-On Tracking",
      initialNotificationContent: "Tracking location updates securely.",
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

/// Call this in your TrackingView's onInit or build structure to listen to the pipeline
void listenToLocationUpdates() {
  FlutterBackgroundService().on('location_update').listen((event) {
    if (event != null && Get.isRegistered<TrackingController>()) {
      final controller = Get.find<TrackingController>();

      final double lat = (event['lat'] as num).toDouble();
      final double lng = (event['lng'] as num).toDouble();
      final double speed = (event['speed'] as num).toDouble();
      final String time = event['time'] as String;

      controller.onNewLocationReceived(
        lat: lat,
        lng: lng,
        speed: speed,
        time: time,
      );
    }
  });
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive and Register Adapters for this isolate
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(LocationPayloadAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(TrackingSessionAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(HourlyLocationLogAdapter());

  final storage = HiveStorageService();
  final dio = Dio(BaseOptions(
    baseUrl: 'https://api.yourdomain.com/v1',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Listen for GPS hardware status changes (On/Off)
  Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
    if (service is AndroidServiceInstance) {
      if (status == ServiceStatus.disabled) {
        service.setForegroundNotificationInfo(
          title: "Tracking Paused",
          content: "GPS is turned off. Please enable it to resume tracking.",
        );
      } else {
        service.setForegroundNotificationInfo(
          title: "Always-On Tracking",
          content: "Tracking location updates securely.",
        );
      }
    }
  });

  /// Background stream runs independently of controller lifecycle status
  try {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15,
      ),
    ).listen((Position position) async {
      final String timeStr = DateTime.now().toIso8601String();

      // 1. Notify UI if the app is open
      service.invoke('location_update', {
        'lat': position.latitude,
        'lng': position.longitude,
        'speed': position.speed,
        'time': timeStr,
      });

      try {
        // 2. Perform Background Persistence & API Sync
        final payload = LocationPayload(
          employeeId: "EMP_12345",
          latitude: position.latitude,
          longitude: position.longitude,
          speed: position.speed,
          timestamp: timeStr,
        );

        // Attempt to sync cached locations first
        final cachedLocations = await storage.getCachedLocations();
        if (cachedLocations.isNotEmpty) {
          await dio.post('/locations/batch',
              data: cachedLocations.map((loc) => loc.toJson()).toList());
          await storage.clearCache();
        }

        // Send current location
        final response = await dio.post('/locations', data: payload.toJson());
        if (response.statusCode != 200 && response.statusCode != 201) {
          await storage.cacheLocation(payload);
        }
      } catch (e) {
        // If network fails, cache the current location
        final payload = LocationPayload(
          employeeId: "EMP_12345",
          latitude: position.latitude,
          longitude: position.longitude,
          speed: position.speed,
          timestamp: timeStr,
        );
        await storage.cacheLocation(payload);
      }
    }, onError: (error) {
      debugPrint("Background Location Stream Error: $error");
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: "Tracking Paused",
          content: "Location permissions are missing or GPS is off.",
        );
      }
    });
  } catch (e) {
    debugPrint("Failed to start location stream: $e");
  }
}
