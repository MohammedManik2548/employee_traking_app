import 'package:hive_flutter/hive_flutter.dart';
import '../models/location_payload.dart';
import '../models/tracking_session.dart';

class HiveStorageService {
  static const String _locationCacheBoxName = 'location_cache_box';
  static const String _trackingSessionBoxName = 'tracking_session_box';

  // Open Boxes
  Future<Box<LocationPayload>> _getLocationBox() async {
    return await Hive.openBox<LocationPayload>(_locationCacheBoxName);
  }

  Future<Box<TrackingSession>> _getSessionBox() async {
    return await Hive.openBox<TrackingSession>(_trackingSessionBoxName);
  }

  // ================= CACHED LOCATION METHODS =================

  Future<void> cacheLocation(LocationPayload payload) async {
    final box = await _getLocationBox();
    await box.add(payload);
  }

  Future<List<LocationPayload>> getCachedLocations() async {
    final box = await _getLocationBox();
    return box.values.toList();
  }

  Future<void> clearCache() async {
    final box = await _getLocationBox();
    await box.clear();
  }

  // ================= TRACKING SESSION METHODS =================

  /// Retrieves all saved tracking sessions stored locally.
  Future<List<TrackingSession>> getAllSessions() async {
    final box = await _getSessionBox();
    return box.values.toList();
  }

  /// Saves or updates a session indexed by its formatted date string (YYYY-MM-DD).
  Future<void> saveOrUpdateSession(TrackingSession session) async {
    final box = await _getSessionBox();
    // Using date as key allows overwriting/updating existing session for the day
    await box.put(session.date, session);
  }
}