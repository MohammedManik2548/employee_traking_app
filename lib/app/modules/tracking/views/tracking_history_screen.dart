import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../controllers/tracking_controller.dart';

class TrackingHistoryScreen extends StatelessWidget {
  final TrackingController controller = Get.find<TrackingController>();

  TrackingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tracking History")),
      body: Obx(() {
        if (controller.historySessions.isEmpty) {
          return const Center(child: Text("No tracking records found."));
        }

        return ListView.builder(
          itemCount: controller.historySessions.length,
          itemBuilder: (context, index) {
            final session = controller.historySessions[index];
            final formattedDate =
            DateFormat('MMM dd, yyyy').format(DateTime.parse(session.date));

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: ExpansionTile(
                title: Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Distance: ${session.totalDistance.toStringAsFixed(2)} km"),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Clock In: ${DateFormat('hh:mm a').format(session.clockInTime)}"),
                        if (session.clockOutTime != null)
                          Text("Clock Out: ${DateFormat('hh:mm a').format(session.clockOutTime!)}"),
                        const Divider(),
                        const Text("Hourly Log Timeline:",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        ...session.hourlyLogs.map((log) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("[${log.time}] ",
                                  style: const TextStyle(
                                      color: Colors.indigo,
                                      fontWeight: FontWeight.bold)),
                              Expanded(
                                  child: Text(log.locationName,
                                      style: const TextStyle(fontSize: 13))),
                            ],
                          ),
                        )),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      }),
    );
  }
}