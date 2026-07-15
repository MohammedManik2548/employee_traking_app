import 'package:get/get.dart';

import '../modules/tracking/bindings/tracking_binding.dart';
import '../modules/tracking/views/tracking_view.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.TRACKING;

  static final routes = [
    GetPage(
      name: Routes.TRACKING,
      page: () => const TrackingView(),
      binding: TrackingBinding(),
    ),
  ];
}