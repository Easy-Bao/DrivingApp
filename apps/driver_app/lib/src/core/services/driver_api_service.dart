import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service wrapper communicating with the Driver backend REST APIs.
class DriverApiService {
  /// The base backend endpoint URI.
  final Uri baseUrl;

  /// Creates an instance of [DriverApiService] configured with a [baseUrl].
  DriverApiService({required this.baseUrl});

  /// Logs in a driver user with credentials.
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
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Toggles the online state of a driver with coordinates.
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
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Fetches standard fare pricing estimates.
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
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Fetches current active bids open on the gateway.
  Future<List<dynamic>> fetchActiveBids(String driverId) async {
    try {
      final response = await http.get(
        baseUrl.replace(
          path: '/bids/active',
          queryParameters: {'driver_id': driverId},
        ),
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

  /// Submits a bid offer on an active session.
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
      return response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  /// Cancels a submitted bid offer.
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
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Fetches historical trips completed by a driver.
  Future<List<dynamic>> fetchTripHistory(String driverId) async {
    try {
      final response = await http.get(
        baseUrl.replace(path: '/drivers/$driverId/trips'),
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

  /// Fetches volume and scoring statistics for a driver.
  Future<Map<String, dynamic>?> fetchStats(String driverId) async {
    try {
      final response = await http.get(
        baseUrl.replace(path: '/drivers/$driverId/stats'),
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

  /// Retrieves profile information for a driver.
  Future<Map<String, dynamic>?> fetchProfile(String driverId) async {
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

  /// Submits telemetry location coordinates update.
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

  /// Retrieves passenger GPS coordinate update for a ride tracking session.
  Future<Map<String, dynamic>?> fetchPassengerLocation(String rideId) async {
    try {
      final response = await http.get(
        baseUrl.replace(path: '/telemetry/location/$rideId'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Retrieves passenger's profile info.
  Future<Map<String, dynamic>?> fetchPassengerProfile(
    String passengerId,
  ) async {
    try {
      final response = await http.get(
        baseUrl.replace(path: '/passengers/$passengerId'),
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

  /// Retrieves details of an active ride.
  Future<Map<String, dynamic>?> getRideStatus(String rideId) async {
    try {
      final response = await http.get(
        baseUrl.replace(path: '/rides/$rideId'),
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
