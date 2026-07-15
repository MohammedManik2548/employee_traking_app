import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../modules/controllers/tracking_controller.dart';

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false, // Keep false! We toggle this explicitly on Clock In / Clock Out
      isForegroundMode: true,
      initialNotificationTitle: "Shift Active",
      initialNotificationContent: "Tracking location updates securely in background.",
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

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Background stream runs independently of controller lifecycle status
  Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 15, // Triggers stream update every 15 meters
    ),
  ).listen((Position position) {
    service.invoke('location_update', {
      'lat': position.latitude,
      'lng': position.longitude,
      'speed': position.speed,
      'time': DateTime.now().toIso8601String(),
    });
  });
}