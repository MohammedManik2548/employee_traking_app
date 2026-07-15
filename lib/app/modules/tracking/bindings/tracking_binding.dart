import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../../data/providers/hive_storage_service.dart';
import '../../controllers/tracking_controller.dart';

class TrackingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<Dio>(() => Dio());
    Get.lazyPut<HiveStorageService>(() => HiveStorageService());

    Get.lazyPut<TrackingController>(
          () => TrackingController(
        Get.find<Dio>(),
        Get.find<HiveStorageService>(),
      ),
    );
  }
}