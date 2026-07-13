import 'dart:convert';
import 'package:core_models/core_models.dart';
import 'package:http/http.dart' as http;

class DriverApiService {
  final Uri baseUrl;

  DriverApiService({required this.baseUrl});

  Map<String, dynamic> _parseMapResponse(
    http.Response response,
    int expectedStatus,
  ) {
    if (response.statusCode == expectedStatus) {
      try {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        throw DataParsingException(
          message: 'Failed to parse response payload: $e',
        );
      }
    }
    throw ServerException(
      statusCode: response.statusCode,
      message: response.body,
    );
  }

  List<dynamic> _parseListResponse(http.Response response, int expectedStatus) {
    if (response.statusCode == expectedStatus) {
      try {
        return jsonDecode(response.body) as List<dynamic>;
      } catch (e) {
        throw DataParsingException(
          message: 'Failed to parse response list: $e',
        );
      }
    }
    throw ServerException(
      statusCode: response.statusCode,
      message: response.body,
    );
  }

  bool _parseBoolResponse(http.Response response, int expectedStatus) {
    if (response.statusCode == expectedStatus) {
      return true;
    }
    throw ServerException(
      statusCode: response.statusCode,
      message: response.body,
    );
  }

  Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        baseUrl.replace(path: '/drivers/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      return _parseMapResponse(response, 200);
    } catch (_) {
      return null;
    }
  }

  Future<bool> toggleOnline({
    required String driverId,
    required bool isOnline,
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await http.post(
        baseUrl.replace(path: '/drivers/$driverId/online'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'isOnline': isOnline, 'lat': lat, 'lng': lng}),
      );
      return _parseBoolResponse(response, 200);
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchFareEstimate({
    required double distanceKm,
    required double durationMinutes,
    String rideType = 'Solo Ride',
  }) async {
    try {
      final response = await http.post(
        baseUrl.replace(path: '/bids/fare'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ride_type': rideType,
          'distance_km': distanceKm,
          'duration_minutes': durationMinutes,
        }),
      );
      return _parseMapResponse(response, 200);
    } catch (_) {
      return null;
    }
  }

  Future<List<dynamic>> fetchActiveBids(String driverId) async {
    try {
      final response = await http.get(
        baseUrl.replace(
          path: '/bids/active',
          queryParameters: {'driver_id': driverId},
        ),
        headers: {'Content-Type': 'application/json'},
      );
      return _parseListResponse(response, 200);
    } catch (_) {
      return [];
    }
  }

  Future<bool> placeBid({
    required String sessionId,
    required String driverId,
    required String driverName,
    required String plateNumber,
    required String vehicleType,
    double? proposedFare,
  }) async {
    try {
      final Map<String, dynamic> bodyData = {
        'driver_id': driverId,
        'driver_name': driverName,
        'plate_number': plateNumber,
        'vehicle_type': vehicleType,
      };
      if (proposedFare != null) {
        bodyData['proposed_fare'] = proposedFare;
      }
      final response = await http.post(
        baseUrl.replace(path: '/bids/$sessionId/offer'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bodyData),
      );
      return _parseBoolResponse(response, 201);
    } catch (_) {
      return false;
    }
  }

  Future<bool> cancelBid({
    required String sessionId,
    required String driverId,
  }) async {
    try {
      final response = await http.post(
        baseUrl.replace(path: '/bids/$sessionId/cancel-offer'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'driver_id': driverId}),
      );
      return _parseBoolResponse(response, 200);
    } catch (_) {
      return false;
    }
  }

  Future<List<dynamic>> fetchTripHistory(String driverId) async {
    try {
      final response = await http.get(
        baseUrl.replace(path: '/drivers/$driverId/trips'),
        headers: {'Content-Type': 'application/json'},
      );
      return _parseListResponse(response, 200);
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
      return _parseMapResponse(response, 200);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchProfile(String driverId) async {
    try {
      final response = await http.get(
        baseUrl.replace(path: '/drivers/$driverId'),
        headers: {'Content-Type': 'application/json'},
      );
      return _parseMapResponse(response, 200);
    } catch (_) {
      return null;
    }
  }

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
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchPassengerLocation(String rideId) async {
    try {
      final response = await http.get(
        baseUrl.replace(path: '/telemetry/location/$rideId'),
      );
      return _parseMapResponse(response, 200);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchPassengerProfile(
    String passengerId,
  ) async {
    try {
      final response = await http.get(
        baseUrl.replace(path: '/passengers/$passengerId'),
        headers: {'Content-Type': 'application/json'},
      );
      return _parseMapResponse(response, 200);
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
      return _parseMapResponse(response, 200);
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
    return _parseBoolResponse(response, 200);
  }

  Future<bool> updateRideStatus(String rideId, String status) async {
    final response = await http.post(
      baseUrl.replace(path: '/rides/$rideId/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );
    return _parseBoolResponse(response, 200);
  }
}
