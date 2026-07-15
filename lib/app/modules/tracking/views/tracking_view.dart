import 'package:employee_tracker/app/modules/tracking/views/tracking_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../controllers/tracking_controller.dart';


class TrackingView extends GetView<TrackingController> {
  const TrackingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'View History',
            onPressed: () {
              Get.to(() => TrackingHistoryScreen());
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Obx(
                () => GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(23.8103, 90.4125),
                zoom: 14,
              ),
              myLocationEnabled: controller.isLocationGranted.value,
              myLocationButtonEnabled: controller.isLocationGranted.value,
              markers: controller.markers.toSet(),
              polylines: controller.polylines.toSet(),
              onMapCreated: (GoogleMapController gController) {
                if (!controller.mapController.isCompleted) {
                  controller.mapController.complete(gController);
                }
              },
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Current Address', style: TextStyle(color: Colors.grey)),
                  Obx(
                        () => Text(
                      controller.currentLocationName.value,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Speed', style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 4),
                          Obx(
                                () => Text(
                              '${controller.currentSpeed.value.toStringAsFixed(1)} km/h',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('Distance', style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 4),
                          Obx(
                                () => Text(
                              '${controller.totalDistance.value.toStringAsFixed(2)} km',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    height: 48,
                    margin: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
                    child: Obx(
                          () => ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: controller.isTracking.value
                              ? Colors.redAccent
                              : Colors.indigo,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          controller.toggleTracking();
                        },
                        child: Text(
                          controller.isTracking.value ? 'CLOCK OUT' : 'CLOCK IN',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}