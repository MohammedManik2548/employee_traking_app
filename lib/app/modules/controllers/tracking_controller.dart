import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import '../../data/models/location_payload.dart';
import '../../data/models/tracking_session.dart';
import '../../data/providers/hive_storage_service.dart';
import '../../services/background_tracking_service.dart';


class TrackingController extends GetxController {
  final Dio _dio;
  final HiveStorageService _hiveStorage;

  TrackingController(this._dio, this._hiveStorage);

  // Reactive UI States
  final RxBool isTracking = false.obs;
  final RxDouble currentSpeed = 0.0.obs;
  final RxDouble totalDistance = 0.0.obs;
  final RxString currentLocationName = "Fetching location...".obs;
  final RxBool isLocationGranted = false.obs;

  // Saved Date-Wise History List
  final RxList<TrackingSession> historySessions = <TrackingSession>[].obs;

  final RxList<Marker> markers = <Marker>[].obs;
  final RxList<Polyline> polylines = <Polyline>[].obs;

  final List<LatLng> _routePoints = [];
  final Completer<GoogleMapController> mapController = Completer();

  DateTime? _clockInTime;
  final List<HourlyLocationLog> _currentHourlyLogs = [];
  int? _lastLoggedHour;

  @override
  void onInit() {
    super.onInit();

    // Bind background channel pipeline stream to GetX handling thread
    listenToLocationUpdates();

    polylines.add(
      Polyline(
        polylineId: const PolylineId('user_path'),
        points: _routePoints,
        color: Colors.indigo,
        width: 5,
      ),
    );

    checkAndRequestLocationPermission();
    loadHistoryFromHive();
  }

  // @override
  // void onInit() {
  //   super.onInit();
  //   polylines.add(
  //     Polyline(
  //       polylineId: const PolylineId('user_path'),
  //       points: _routePoints,
  //       color: Colors.indigo,
  //       width: 5,
  //     ),
  //   );
  //
  //   checkAndRequestLocationPermission();
  //   loadHistoryFromHive();
  // }

  // ================= PERMISSION LOGIC =================

  Future<void> checkAndRequestLocationPermission() async {
    PermissionStatus status = await Permission.location.status;

    if (status.isGranted) {
      isLocationGranted.value = true;
    } else if (status.isPermanentlyDenied) {
      _showGoToSettingsDialog();
    } else {
      _requestLocationPermission();
    }
  }

  Future<void> _requestLocationPermission() async {
    PermissionStatus status = await Permission.location.request();

    if (status.isGranted) {
      isLocationGranted.value = true;
    } else if (status.isPermanentlyDenied) {
      _showGoToSettingsDialog();
    } else if (status.isDenied) {
      _showRetryDialog();
    }
  }

  void _showGoToSettingsDialog() {
    Get.defaultDialog(
      title: "Location Permission Denied",
      middleText:
      "Location access is permanently disabled. Please allow location permission in settings to track on the map.",
      textCancel: "Cancel",
      textConfirm: "Go to Settings",
      confirmTextColor: Colors.white,
      onConfirm: () async {
        Get.back();
        await openAppSettings();
      },
    );
  }

  void _showRetryDialog() {
    Get.defaultDialog(
      title: "Permission Required",
      middleText:
      "Location permission is required for live map tracking. Would you like to grant permission?",
      textCancel: "Cancel",
      textConfirm: "Allow",
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        _requestLocationPermission();
      },
    );
  }

  // ================= LOCATION & TRACKING LOGIC =================

  Future<void> onNewLocationReceived({
    required double lat,
    required double lng,
    required double speed,
    required String time,
    String employeeId = "EMP_12345",
  }) async {
    if (!isTracking.value) return;

    final newPoint = LatLng(lat, lng);

    // 1. Calculate cumulative distance and speed
    if (_routePoints.isNotEmpty) {
      final lastPoint = _routePoints.last;
      final distanceInMeters = Geolocator.distanceBetween(
        lastPoint.latitude,
        lastPoint.longitude,
        newPoint.latitude,
        newPoint.longitude,
      );
      totalDistance.value += (distanceInMeters / 1000.0);
    }
    currentSpeed.value = speed > 0 ? speed * 3.6 : 0.0;

    // 2. Reverse Geocode Lat/Lng into Address
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;
        currentLocationName.value =
        "${place.street}, ${place.subLocality}, ${place.locality}";
      }
    } catch (e) {
      currentLocationName.value = "Unknown Location Address";
    }

    // 3. Log hourly summary snapshot
    _checkAndLogHourlyProgress(lat, lng, currentLocationName.value);

    // 4. Update Polylines and Map Markers
    _routePoints.add(newPoint);
    polylines.value = [
      Polyline(
        polylineId: const PolylineId('user_path'),
        points: List.from(_routePoints),
        color: Colors.indigo,
        width: 5,
      )
    ];

    markers.value = [
      Marker(
        markerId: const MarkerId('current_user'),
        position: newPoint,
        infoWindow: InfoWindow(title: 'Your Location', snippet: currentLocationName.value),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      )
    ];

    // 5. Animate Map Camera
    if (mapController.isCompleted) {
      final googleMapCtrl = await mapController.future;
      googleMapCtrl.animateCamera(CameraUpdate.newLatLng(newPoint));
    }

    // 6. Cache/Send Raw Location Data
    final payload = LocationPayload(
      employeeId: employeeId,
      latitude: lat,
      longitude: lng,
      speed: speed,
      timestamp: time,
    );

    await sendOrCacheLocation(payload);
  }

  void toggleTracking() async {
    if (!isLocationGranted.value) {
      checkAndRequestLocationPermission();
      return;
    }

    isTracking.value = !isTracking.value;
    final backgroundService = FlutterBackgroundService();

    if (isTracking.value) {
      // --- CLOCK IN ---
      _clockInTime = DateTime.now();
      _currentHourlyLogs.clear();
      _lastLoggedHour = null;
      totalDistance.value = 0.0;

      // START OS Background foreground process loop
      bool isRunning = await backgroundService.isRunning();
      if (!isRunning) {
        await backgroundService.startService();
      }
    } else {
      // --- CLOCK OUT ---
      currentSpeed.value = 0.0;
      _saveCurrentSessionToHistory();

      // STOP OS Background processing loop completely
      bool isRunning = await backgroundService.isRunning();
      if (isRunning) {
        backgroundService.invoke('stopService');
      }
    }
  }

  // void toggleTracking() {
  //   if (!isLocationGranted.value) {
  //     checkAndRequestLocationPermission();
  //     return;
  //   }
  //
  //   isTracking.value = !isTracking.value;
  //
  //   if (isTracking.value) {
  //     // Clock In
  //     _clockInTime = DateTime.now();
  //     _currentHourlyLogs.clear();
  //     _lastLoggedHour = null;
  //     totalDistance.value = 0.0;
  //   } else {
  //     // Clock Out
  //     currentSpeed.value = 0.0;
  //     _saveCurrentSessionToHistory();
  //   }
  // }

  void _checkAndLogHourlyProgress(double lat, double lng, String addressName) {
    final now = DateTime.now();
    final currentHour = now.hour;

    if (_lastLoggedHour == null || _lastLoggedHour != currentHour) {
      _lastLoggedHour = currentHour;
      _currentHourlyLogs.add(
        HourlyLocationLog(
          time: DateFormat('hh:mm a').format(now),
          locationName: addressName,
          latitude: lat,
          longitude: lng,
        ),
      );
    }
  }

  Future<void> loadHistoryFromHive() async {
    final sessions = await _hiveStorage.getAllSessions();
    historySessions.assignAll(sessions);
  }

  Future<void> _saveCurrentSessionToHistory() async {
    if (_clockInTime == null) return;

    final todayStr = DateFormat('yyyy-MM-dd').format(_clockInTime!);

    // Convert List<LatLng> to a serializable List<List<double>> for Hive
    final serializableCoords = _routePoints.map((latLng) => [latLng.latitude, latLng.longitude]).toList();

    final newSession = TrackingSession(
      date: todayStr,
      clockInTime: _clockInTime!,
      clockOutTime: DateTime.now(),
      totalDistance: totalDistance.value,
      hourlyLogs: List.from(_currentHourlyLogs),
      routeCoordinates: serializableCoords, // Pass the tracked route coordinates here
    );

    await _hiveStorage.saveOrUpdateSession(newSession);

    // Clear the active route tracking path for a fresh session
    _routePoints.clear();

    await loadHistoryFromHive();
    _sendHistoryToBackend(newSession);
  }

  Future<void> sendOrCacheLocation(LocationPayload payload) async {
    try {
      final response = await _dio.post('/locations', data: payload.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) {
        await syncCachedLocations();
      } else {
        await _hiveStorage.cacheLocation(payload);
      }
    } catch (e) {
      await _hiveStorage.cacheLocation(payload);
    }
  }

  Future<void> syncCachedLocations() async {
    final cachedLocations = await _hiveStorage.getCachedLocations();
    if (cachedLocations.isEmpty) return;

    try {
      final response = await _dio.post(
        '/locations/batch',
        data: cachedLocations.map((loc) => loc.toJson()).toList(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        await _hiveStorage.clearCache();
      }
    } catch (_) {}
  }

  Future<void> _sendHistoryToBackend(TrackingSession session) async {
    try {
      await _dio.post('/tracking/summary', data: {
        "date": session.date,
        "clock_in": session.clockInTime.toIso8601String(),
        "clock_out": session.clockOutTime?.toIso8601String(),
        "total_distance_km": session.totalDistance,
        "history": session.hourlyLogs
            .map((log) => {
          "time": log.time,
          "address": log.locationName,
          "latitude": log.latitude,
          "longitude": log.longitude
        })
            .toList()
      });
    } catch (_) {}
  }
}