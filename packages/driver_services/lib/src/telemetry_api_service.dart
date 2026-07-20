import 'package:driver_services/src/base_api_client.dart';

class TelemetryApiService extends BaseApiClient {
  TelemetryApiService({required super.baseUrl, super.dio});

  Future<bool> updateLocation({
    required String driverId,
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await clientDio.post(
        '/telemetry/location',
        data: {'driverId': driverId, 'lat': lat, 'lng': lng},
      );
      return parseBoolResponse(response, 200);
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchPassengerLocation(String rideId) async {
    try {
      final response = await clientDio.get('/telemetry/location/$rideId');
      return parseMapResponse(response, 200);
    } catch (_) {
      return null;
    }
  }
}
