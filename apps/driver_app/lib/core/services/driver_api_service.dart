/// Driver API Service: manages server communication for driver authentication, online status updates, and ride acceptance.
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:driver_app/core/config/env_config.dart';

class DriverApiService {
  DriverApiService._();

  static final String _baseUrl = EnvConfig.driverServiceUrl;

  static Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/drivers/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> toggleOnline({
    required String driverId,
    required bool isOnline,
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/drivers/$driverId/online'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'isOnline': isOnline, 'lat': lat, 'lng': lng}),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> fetchFareEstimate({
    required double distanceKm,
    required double durationMinutes,
    String rideType = 'Solo Ride',
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

  static Future<List<dynamic>> fetchActiveBids(String driverId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/bids/active?driver_id=$driverId'),
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

  static Future<bool> placeBid({
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
        Uri.parse('$_baseUrl/bids/$sessionId/offer'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bodyData),
      );
      return response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> cancelBid({
    required String sessionId,
    required String driverId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/bids/$sessionId/cancel-offer'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'driver_id': driverId}),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<List<dynamic>> fetchTripHistory(String driverId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/drivers/$driverId/trips'),
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

  static Future<Map<String, dynamic>?> fetchStats(String driverId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/drivers/$driverId/stats'),
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

  static Future<Map<String, dynamic>?> fetchProfile(String driverId) async {
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
}
