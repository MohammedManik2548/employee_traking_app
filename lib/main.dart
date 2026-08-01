import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'app/data/models/location_payload.dart';
import 'app/data/models/tracking_session.dart';
import 'app/routes/app_pages.dart';
import 'app/services/background_tracking_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  /// Register all Hive Adapters
  Hive.registerAdapter(LocationPayloadAdapter());
  Hive.registerAdapter(TrackingSessionAdapter());
  Hive.registerAdapter(HourlyLocationLogAdapter());

  /// Initialize Background Service
  await initializeBackgroundService();

  // If permission was already granted (from a previous session), start it immediately
  if (await Permission.location.isGranted) {
    final service = FlutterBackgroundService();
    if (!await service.isRunning()) {
      await service.startService();
    }
  }

  /// Build command:
  /// flutter build apk --split-per-abi --release
  runApp(
    GetMaterialApp(
      title: "Employee Tracker",
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
    ),
  );
}