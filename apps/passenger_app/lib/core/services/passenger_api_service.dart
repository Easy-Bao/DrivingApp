import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:passenger_app/core/config/env_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PassengerApiService {
  PassengerApiService._();

  static final String _baseUrl = EnvConfig.passengerServiceUrl ?? 'http://127.0.0.1:8080';

  static Future<Map<String, String>> _getRequestHeaders() async {
    final SharedPreferences prefsInstance = await SharedPreferences.getInstance();
    final String jsonWebToken = prefsInstance.getString('jwt_token') ?? '';
    final Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
    };
    if (jsonWebToken.isNotEmpty) {
      requestHeaders['Authorization'] = 'Bearer $jsonWebToken';
    }
    return requestHeaders;
  }

  static Future<Map<String, dynamic>?> registerPassenger({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/passengers'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
      }),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<bool> verifyOtp({
    required String email,
    required String code,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/passengers/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'code': code,
      }),
    );
    return response.statusCode == 200;
  }

  static Future<bool> forgotPassword({required String email}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/passengers/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>?> updateProfile({
    required String id,
    required String name,
    required String phone,
    required String email,
  }) async {
    final Map<String, String> requestHeaders = await _getRequestHeaders();
    final response = await http.put(
      Uri.parse('$_baseUrl/passengers/$id'),
      headers: requestHeaders,
      body: jsonEncode({
        'name': name,
        'phone': phone,
        'email': email,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<Map<String, dynamic>?> createRideRequest({
    required String passengerId,
    required String rideType,
    required double pickupLat,
    required double pickupLng,
    required String pickupName,
    required double dropoffLat,
    required double dropoffLng,
    required String dropoffName,
    required double fare,
  }) async {
    final typeParam = rideType.toLowerCase().contains('share') ? 'share-bao' : 'solo-ride';
    final Map<String, String> requestHeaders = await _getRequestHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/rides'),
      headers: requestHeaders,
      body: jsonEncode({
        'passenger_id': passengerId,
        'ride_type': typeParam,
        'pickup_latitude': pickupLat,
        'pickup_longitude': pickupLng,
        'pickup_name': pickupName,
        'dropoff_latitude': dropoffLat,
        'dropoff_longitude': dropoffLng,
        'dropoff_name': dropoffName,
        'fare': fare,
      }),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<List<dynamic>> fetchRideHistory(String passengerId) async {
    final Map<String, String> requestHeaders = await _getRequestHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/passengers/$passengerId/rides'),
      headers: requestHeaders,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    return [];
  }

  static Future<List<dynamic>> fetchNotifications(String passengerId) async {
    try {
      final Map<String, String> requestHeaders = await _getRequestHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/passengers/$passengerId/notifications'),
        headers: requestHeaders,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getRideStatus(String rideId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/rides/$rideId'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<bool> updateRideStatus(String rideId, String status) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/rides/$rideId/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );
    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>?> fetchDriverLocation(String driverId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/telemetry/location/$driverId'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> updateLocation({
    required String rideId,
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/telemetry/location'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'driverId': rideId,
          'lat': lat,
          'lng': lng,
        }),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getPassengerProfile(
    String passengerId,
  ) async {
    try {
      final Map<String, String> requestHeaders = await _getRequestHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/passengers/$passengerId'),
        headers: requestHeaders,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (error) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> fetchFareEstimate({
    required String rideType,
    required double distanceKm,
    required double durationMinutes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/bids/fare'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ride_type': rideType,
          'distance_km': distanceKm,
          'duration_minutes': durationMinutes,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> openBidSession({
    required String passengerId,
    required String rideType,
    required double pickupLat,
    required double pickupLng,
    required String pickupName,
    required double dropoffLat,
    required double dropoffLng,
    required String dropoffName,
    required double distanceKm,
    required double durationMinutes,
    String? targetDriverId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/bids'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'passenger_id': passengerId,
          'ride_type': rideType,
          'pickup_latitude': pickupLat,
          'pickup_longitude': pickupLng,
          'pickup_name': pickupName,
          'dropoff_latitude': dropoffLat,
          'dropoff_longitude': dropoffLng,
          'dropoff_name': dropoffName,
          'distance_km': distanceKm,
          'duration_minutes': durationMinutes,
          'target_driver_id': targetDriverId,
        }),
      );
      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<dynamic>> pollBidOffers(String sessionId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/bids/$sessionId/offers'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> acceptBidOffer({
    required String sessionId,
    required String offerId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/bids/$sessionId/accept'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'offer_id': offerId,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> cancelBidSession(String sessionId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/bids/$sessionId'),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getBidSession(String sessionId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/bids/$sessionId'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<dynamic>> fetchOnlineDrivers() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/drivers/online'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getDriverProfile(String driverId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/drivers/$driverId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> fetchDriverStats(String driverId) async {
    try {
      final driverStatsResponse = await http.get(
        Uri.parse('$_baseUrl/drivers/$driverId/stats'),
        headers: {'Content-Type': 'application/json'},
      );
      if (driverStatsResponse.statusCode == 200) {
        return jsonDecode(driverStatsResponse.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<dynamic>> fetchDriverReviews(String driverId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/drivers/$driverId/reviews'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
