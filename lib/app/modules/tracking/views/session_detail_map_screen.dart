import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../data/models/tracking_session.dart';

class SessionDetailMapScreen extends StatelessWidget {
  final TrackingSession session;

  const SessionDetailMapScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    // 1. Convert historical coordinates back into Google Map LatLng instances
    final List<LatLng> polylinePoints = session.routeCoordinates
        .map((coord) => LatLng(coord[0], coord[1]))
        .toList();

    final Set<Polyline> polylines = {
      Polyline(
        polylineId: const PolylineId('history_route_path'),
        points: polylinePoints,
        color: Colors.indigo,
        width: 5,
      ),
    };

    // 2. Generate markers for the hourly check-in stops
    final Set<Marker> markers = {};
    for (int i = 0; i < session.hourlyLogs.length; i++) {
      final log = session.hourlyLogs[i];
      markers.add(
        Marker(
          markerId: MarkerId('stop_$i'),
          position: LatLng(log.latitude, log.longitude),
          infoWindow: InfoWindow(
            title: log.time,
            snippet: log.locationName,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            i == 0 ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueOrange,
          ),
        ),
      );
    }

    // Fallback default target if route data happens to be empty
    final initialTarget = polylinePoints.isNotEmpty
        ? polylinePoints.first
        : const LatLng(23.8103, 90.4125);

    return Scaffold(
      appBar: AppBar(
        title: Text("Route Details: ${session.date}"),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: initialTarget,
          zoom: 15,
        ),
        polylines: polylines,
        markers: markers,
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
      ),
    );
  }
}