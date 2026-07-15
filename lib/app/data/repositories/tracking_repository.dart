import 'package:dio/dio.dart';
import '../models/location_payload.dart';
import '../providers/dio_client.dart';

class TrackingRepository {
  final DioClient _dioClient;

  TrackingRepository(this._dioClient);

  Future sendLocation(LocationPayload payload) async {
    try {
      final response = await _dioClient.instance.post(
        '/employee/track',
        data: payload.toJson(),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      print("Failed to post location: ${e.message}");
      return false;
    }
  }
}