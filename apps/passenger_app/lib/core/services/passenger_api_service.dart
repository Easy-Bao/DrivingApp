/// Passenger API Service: manages server communication for authentication, OTP verification, ride requests, and profile updates.
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:passenger_app/core/config/env_config.dart';

class PassengerApiService {
  PassengerApiService._();

  static final String _baseUrl = EnvConfig.passengerServiceUrl ?? 'http://127.0.0.1:8080';

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
    final response = await http.put(
      Uri.parse('$_baseUrl/passengers/$id'),
      headers: {'Content-Type': 'application/json'},
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
    final response = await http.post(
      Uri.parse('$_baseUrl/rides'),
      headers: {'Content-Type': 'application/json'},
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
    final response = await http.get(
      Uri.parse('$_baseUrl/passengers/$passengerId/rides'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    return [];
  }

  static Future<List<dynamic>> fetchNotifications(String passengerId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/passengers/$passengerId/notifications'),
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

  /// Fetches the authenticated passenger's profile by [passengerId].
  /// Returns the raw JSON map from `GET /passengers/:id`, or `null` on failure.
  static Future<Map<String, dynamic>?> getPassengerProfile(
    String passengerId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/passengers/$passengerId'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /**
   * Stateless fare estimate calculation from bidding-service via POST /bids/fare.
   */
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

  /**
   * Opens a bidding session for a ride request via POST /bids.
   */
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

  /**
   * Polls pending driver offers for a bid session via GET /bids/:id/offers.
   */
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

  /**
   * Passenger accepts a specific driver offer via POST /bids/:id/accept.
   */
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

  /**
   * Passenger cancels an active bidding session via DELETE /bids/:id.
   */
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

  /**
   * Gets bid session status via GET /bids/:id.
   */
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
}
