import 'dart:convert';

import 'package:driver_services/src/base_api_client.dart';
import 'package:http/http.dart' as http;

class TelemetryApiService extends BaseApiClient {
  TelemetryApiService({required super.baseUrl});

  Future<bool> updateLocation({
    required String driverId,
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await http.post(
        baseUrl.replace(path: '/telemetry/location'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'driverId': driverId, 'lat': lat, 'lng': lng}),
      );
      return parseBoolResponse(response, 200);
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchPassengerLocation(String rideId) async {
    try {
      final response = await http.get(
        baseUrl.replace(path: '/telemetry/location/$rideId'),
      );
      return parseMapResponse(response, 200);
    } catch (_) {
      return null;
    }
  }
}
