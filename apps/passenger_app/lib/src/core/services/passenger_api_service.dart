import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service wrapper communicating with the Passenger backend REST APIs.
class PassengerApiService {
  /// The base backend endpoint URI.
  final Uri baseUrl;

  /// Creates an instance of [PassengerApiService] configured with a [baseUrl].
  PassengerApiService({required this.baseUrl});

  Future<Map<String, String>> _getRequestHeaders() async {
    final SharedPreferences prefsInstance =
        await SharedPreferences.getInstance();
    final String jsonWebToken = prefsInstance.getString('jwt_token') ?? '';
    final Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
    };
    if (jsonWebToken.isNotEmpty) {
      requestHeaders['Authorization'] = 'Bearer $jsonWebToken';
    }
    return requestHeaders;
  }

  /// Registers a new passenger user.
  Future<Map<String, dynamic>?> registerPassenger({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await http.post(
      baseUrl.replace(path: '/passengers'),
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

  /// Verifies an OTP code for a passenger email.
  Future<bool> verifyOtp({required String email, required String code}) async {
    final response = await http.post(
      baseUrl.replace(path: '/passengers/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );
    return response.statusCode == 200;
  }

  /// Initiates password recovery.
  Future<bool> forgotPassword({required String email}) async {
    final response = await http.post(
      baseUrl.replace(path: '/passengers/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    return response.statusCode == 200;
  }

  /// Updates profile information for a passenger.
  Future<Map<String, dynamic>?> updateProfile({
    required String id,
    required String name,
    required String phone,
    required String email,
  }) async {
    final Map<String, String> requestHeaders = await _getRequestHeaders();
    final response = await http.put(
      baseUrl.replace(path: '/passengers/$id'),
      headers: requestHeaders,
      body: jsonEncode({'name': name, 'phone': phone, 'email': email}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  /// Submits a ride request to the match maker.
  Future<Map<String, dynamic>?> createRideRequest({
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
    final typeParam = rideType.toLowerCase().contains('share')
        ? 'share-bao'
        : 'solo-ride';
    final Map<String, String> requestHeaders = await _getRequestHeaders();
    final response = await http.post(
      baseUrl.replace(path: '/rides'),
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

  /// Fetches historical rides completed by the passenger.
  Future<List<dynamic>> fetchRideHistory(String passengerId) async {
    final Map<String, String> requestHeaders = await _getRequestHeaders();
    final response = await http.get(
      baseUrl.replace(path: '/passengers/$passengerId/rides'),
      headers: requestHeaders,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    return [];
  }

  /// Fetches recent notifications received by the passenger.
  Future<List<dynamic>> fetchNotifications(String passengerId) async {
    try {
      final Map<String, String> requestHeaders = await _getRequestHeaders();
      final response = await http.get(
        baseUrl.replace(path: '/passengers/$passengerId/notifications'),
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

  /// Retrieves the current status details of a specific ride.
  Future<Map<String, dynamic>?> getRideStatus(String rideId) async {
    final response = await http.get(baseUrl.replace(path: '/rides/$rideId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  /// Updates status for an active ride.
  Future<bool> updateRideStatus(String rideId, String status) async {
    final response = await http.post(
      baseUrl.replace(path: '/rides/$rideId/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );
    return response.statusCode == 200;
  }

  /// Fetches the current location telemetry of a driver.
  Future<Map<String, dynamic>?> fetchDriverLocation(String driverId) async {
    try {
      final response = await http.get(
        baseUrl.replace(path: '/telemetry/location/$driverId'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Submits telemetry location update for a ride tracking session.
  Future<bool> updateLocation({
    required String rideId,
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await http.post(
        baseUrl.replace(path: '/telemetry/location'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'driverId': rideId, 'lat': lat, 'lng': lng}),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Retrieves detailed profile metadata for a passenger.
  Future<Map<String, dynamic>?> getPassengerProfile(String passengerId) async {
    try {
      final Map<String, String> requestHeaders = await _getRequestHeaders();
      final response = await http.get(
        baseUrl.replace(path: '/passengers/$passengerId'),
        headers: requestHeaders,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Fetches standard fare pricing estimates based on trip parameters.
  Future<Map<String, dynamic>?> fetchFareEstimate({
    required String rideType,
    required double distanceKm,
    required double durationMinutes,
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
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Starts a bidding session on the gateway.
  Future<Map<String, dynamic>?> openBidSession({
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
        baseUrl.replace(path: '/bids'),
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

  /// Retrieves list of offers received for a bid session.
  Future<List<dynamic>> pollBidOffers(String sessionId) async {
    try {
      final response = await http.get(
        baseUrl.replace(path: '/bids/$sessionId/offers'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Accepts a driver's bid offer.
  Future<Map<String, dynamic>?> acceptBidOffer({
    required String sessionId,
    required String offerId,
  }) async {
    try {
      final response = await http.post(
        baseUrl.replace(path: '/bids/$sessionId/accept'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'offer_id': offerId}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Cancels an active bid session.
  Future<bool> cancelBidSession(String sessionId) async {
    try {
      final response = await http.delete(
        baseUrl.replace(path: '/bids/$sessionId'),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Retrieves the active metadata of a bid session.
  Future<Map<String, dynamic>?> getBidSession(String sessionId) async {
    try {
      final response = await http.get(
        baseUrl.replace(path: '/bids/$sessionId'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Fetches list of drivers currently active on the grid.
  Future<List<dynamic>> fetchOnlineDrivers() async {
    try {
      final response = await http.get(baseUrl.replace(path: '/drivers/online'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Retrieves a driver's registration profile details.
  Future<Map<String, dynamic>?> getDriverProfile(String driverId) async {
    try {
      final response = await http.get(
        baseUrl.replace(path: '/drivers/$driverId'),
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

  /// Fetches trip volume and scoring statistics for a driver.
  Future<Map<String, dynamic>?> fetchDriverStats(String driverId) async {
    try {
      final driverStatsResponse = await http.get(
        baseUrl.replace(path: '/drivers/$driverId/stats'),
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

  /// Retrieves reviews and comment history posted for a driver.
  Future<List<dynamic>> fetchDriverReviews(String driverId) async {
    try {
      final response = await http.get(
        baseUrl.replace(path: '/drivers/$driverId/reviews'),
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
