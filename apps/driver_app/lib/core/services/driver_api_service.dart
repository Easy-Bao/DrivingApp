/// Driver API Service: manages server communication for driver authentication, online status updates, and ride acceptance.
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:driver_app/core/config/env_config.dart';

class DriverApiService {
  DriverApiService._();

  static final String _baseUrl = EnvConfig.driverServiceUrl;

  /**
   * Authenticates a driver via POST /drivers/login.
   * Returns the raw JSON response containing driver profile and token, or null on failure.
   */
  static Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/drivers/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
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

  /**
   * Toggles online/offline status for a driver via POST /drivers/:id/online.
   * Returns true if status was successfully updated on the server.
   */
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
        body: jsonEncode({
          'isOnline': isOnline,
          'lat': lat,
          'lng': lng,
        }),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /**
   * Calculates dynamic fare estimate via POST /bids/fare.
   */
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

  /**
   * Fetches active, non-expired bid sessions from the bidding-service.
   * Returns a list of bid session maps.
   */
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

  /**
   * Places an offer (bid) on a passenger's bid session via POST /bids/:id/offer.
   * Returns true if successfully submitted.
   */
  static Future<bool> placeBid({
    required String sessionId,
    required String driverId,
    required String driverName,
    required String plateNumber,
    required String vehicleType,
    double? proposedFare,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/bids/$sessionId/offer'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'driver_id': driverId,
          'driver_name': driverName,
          'plate_number': plateNumber,
          'vehicle_type': vehicleType,
          if (proposedFare != null) 'proposed_fare': proposedFare,
        }),
      );
      return response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  /**
   * Cancels a pending offer placed by a driver on a session via POST /bids/:id/cancel-offer.
   * Returns true if successfully withdrawn.
   */
  static Future<bool> cancelBid({
    required String sessionId,
    required String driverId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/bids/$sessionId/cancel-offer'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'driver_id': driverId,
        }),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /**
   * Fetches the driver's trip history via GET /drivers/:id/trips.
   * Returns a list of completed/canceled trips.
   */
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
}
