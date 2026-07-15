import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
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