import 'dart:convert';
import 'package:core_models/core_models.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PassengerApiService {
  final Uri baseUrl;

  PassengerApiService({required this.baseUrl});

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
    return _parseMapResponse(response, 201);
  }

  Future<bool> verifyOtp({required String email, required String code}) async {
    final response = await http.post(
      baseUrl.replace(path: '/passengers/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );
    return _parseBoolResponse(response, 200);
  }

  Future<bool> forgotPassword({required String email}) async {
    final response = await http.post(
      baseUrl.replace(path: '/passengers/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    return _parseBoolResponse(response, 200);
  }

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
    return _parseMapResponse(response, 200);
  }

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
    return _parseMapResponse(response, 201);
  }

  Future<List<dynamic>> fetchRideHistory(String passengerId) async {
    final Map<String, String> requestHeaders = await _getRequestHeaders();
    final response = await http.get(
      baseUrl.replace(path: '/passengers/$passengerId/rides'),
      headers: requestHeaders,
    );
    return _parseListResponse(response, 200);
  }

  Future<List<dynamic>> fetchNotifications(String passengerId) async {
    final Map<String, String> requestHeaders = await _getRequestHeaders();
    final response = await http.get(
      baseUrl.replace(path: '/passengers/$passengerId/notifications'),
      headers: requestHeaders,
    );
    return _parseListResponse(response, 200);
  }

  Future<Map<String, dynamic>?> getRideStatus(String rideId) async {
    final response = await http.get(baseUrl.replace(path: '/rides/$rideId'));
    return _parseMapResponse(response, 200);
  }

  Future<bool> updateRideStatus(String rideId, String status) async {
    final response = await http.post(
      baseUrl.replace(path: '/rides/$rideId/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );
    return _parseBoolResponse(response, 200);
  }

  Future<Map<String, dynamic>?> fetchDriverLocation(String driverId) async {
    final response = await http.get(
      baseUrl.replace(path: '/telemetry/location/$driverId'),
    );
    return _parseMapResponse(response, 200);
  }

  Future<bool> updateLocation({
    required String rideId,
    required double lat,
    required double lng,
  }) async {
    final response = await http.post(
      baseUrl.replace(path: '/telemetry/location'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'driverId': rideId, 'lat': lat, 'lng': lng}),
    );
    return _parseBoolResponse(response, 200);
  }

  Future<Map<String, dynamic>?> getPassengerProfile(String passengerId) async {
    final Map<String, String> requestHeaders = await _getRequestHeaders();
    final response = await http.get(
      baseUrl.replace(path: '/passengers/$passengerId'),
      headers: requestHeaders,
    );
    return _parseMapResponse(response, 200);
  }

  Future<Map<String, dynamic>?> fetchFareEstimate({
    required String rideType,
    required double distanceKm,
    required double durationMinutes,
  }) async {
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
  }

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
    return _parseMapResponse(response, 201);
  }

  Future<List<dynamic>> pollBidOffers(String sessionId) async {
    final response = await http.get(
      baseUrl.replace(path: '/bids/$sessionId/offers'),
    );
    return _parseListResponse(response, 200);
  }

  Future<Map<String, dynamic>?> acceptBidOffer({
    required String sessionId,
    required String offerId,
  }) async {
    final response = await http.post(
      baseUrl.replace(path: '/bids/$sessionId/accept'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'offer_id': offerId}),
    );
    return _parseMapResponse(response, 200);
  }

  Future<bool> cancelBidSession(String sessionId) async {
    final response = await http.delete(
      baseUrl.replace(path: '/bids/$sessionId'),
    );
    return _parseBoolResponse(response, 200);
  }

  Future<Map<String, dynamic>?> getBidSession(String sessionId) async {
    final response = await http.get(baseUrl.replace(path: '/bids/$sessionId'));
    return _parseMapResponse(response, 200);
  }

  Future<List<dynamic>> fetchOnlineDrivers() async {
    final response = await http.get(baseUrl.replace(path: '/drivers/online'));
    return _parseListResponse(response, 200);
  }

  Future<Map<String, dynamic>?> getDriverProfile(String driverId) async {
    final response = await http.get(
      baseUrl.replace(path: '/drivers/$driverId'),
      headers: {'Content-Type': 'application/json'},
    );
    return _parseMapResponse(response, 200);
  }

  Future<Map<String, dynamic>?> fetchDriverStats(String driverId) async {
    final driverStatsResponse = await http.get(
      baseUrl.replace(path: '/drivers/$driverId/stats'),
      headers: {'Content-Type': 'application/json'},
    );
    return _parseMapResponse(driverStatsResponse, 200);
  }

  Future<List<dynamic>> fetchDriverReviews(String driverId) async {
    final response = await http.get(
      baseUrl.replace(path: '/drivers/$driverId/reviews'),
      headers: {'Content-Type': 'application/json'},
    );
    return _parseListResponse(response, 200);
  }
}
