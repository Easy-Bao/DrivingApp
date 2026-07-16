import 'dart:convert';

import 'package:driver_services/src/base_api_client.dart';
import 'package:http/http.dart' as http;

class TripApiService extends BaseApiClient {
  TripApiService({required super.baseUrl});

  Future<List<dynamic>> fetchTripHistory(String driverId) async {
    try {
      final response = await http.get(
        baseUrl.replace(path: '/drivers/$driverId/trips'),
        headers: {'Content-Type': 'application/json'},
      );
      return parseListResponse(response, 200);
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchStats(String driverId) async {
    try {
      final response = await http.get(
        baseUrl.replace(path: '/drivers/$driverId/stats'),
        headers: {'Content-Type': 'application/json'},
      );
      return parseMapResponse(response, 200);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getRideStatus(String rideId) async {
    try {
      final response = await http.get(
        baseUrl.replace(path: '/rides/$rideId'),
        headers: {'Content-Type': 'application/json'},
      );
      return parseMapResponse(response, 200);
    } catch (_) {
      return null;
    }
  }

  Future<bool> acceptRide({
    required String rideId,
    required String driverId,
    required String driverName,
    required String driverRating,
    required String vehicleType,
    required String plateNumber,
  }) async {
    final response = await http.post(
      baseUrl.replace(path: '/rides/$rideId/accept'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'driver_id': driverId,
        'driver_name': driverName,
        'driver_rating': driverRating,
        'vehicle_type': vehicleType,
        'plate_number': plateNumber,
      }),
    );
    return parseBoolResponse(response, 200);
  }

  Future<bool> updateRideStatus(String rideId, String status) async {
    final response = await http.post(
      baseUrl.replace(path: '/rides/$rideId/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );
    return parseBoolResponse(response, 200);
  }
}
