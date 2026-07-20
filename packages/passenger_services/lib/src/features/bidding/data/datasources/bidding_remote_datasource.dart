import 'package:dio/dio.dart';
import 'package:passenger_services/src/core/network/base_api_client.dart';
import 'package:session_service/session_service.dart';

class BiddingRemoteDataSource extends BaseApiClient {
  final SecureSessionService _sessionService;

  BiddingRemoteDataSource({
    required super.baseUrl,
    required SecureSessionService sessionService,
    super.dio,
  }) : _sessionService = sessionService;

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
    final response = await clientDio.post(
      '/bids',
      data: {
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
      },
    );
    return parseMapResponse(response, 201);
  }

  Future<Map<String, dynamic>?> getBidSession(String sessionId) async {
    final response = await clientDio.get('/bids/$sessionId');
    return parseMapResponse(response, 200);
  }

  Future<List<dynamic>> pollBidOffers(String sessionId) async {
    final response = await clientDio.get('/bids/$sessionId/offers');
    return parseListResponse(response, 200);
  }

  Future<Map<String, dynamic>?> acceptBidOffer({
    required String sessionId,
    required String offerId,
  }) async {
    final response = await clientDio.post(
      '/bids/$sessionId/accept',
      data: {'offer_id': offerId},
    );
    return parseMapResponse(response, 200);
  }

  Future<bool> cancelBidSession(String sessionId) async {
    final response = await clientDio.delete('/bids/$sessionId');
    return parseBoolResponse(response, 200);
  }

  Future<Map<String, dynamic>?> fetchFareEstimate({
    required String rideType,
    required double distanceKm,
    required double durationMinutes,
  }) async {
    final response = await clientDio.post(
      '/bids/fare',
      data: {
        'ride_type': rideType,
        'distance_km': distanceKm,
        'duration_minutes': durationMinutes,
      },
    );
    return parseMapResponse(response, 200);
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
    final typeParam =
        rideType.toLowerCase().contains('share') ? 'share-bao' : 'solo-ride';
    final requestHeaders = await _getRequestHeaders();
    final response = await clientDio.post(
      '/rides',
      options: Options(headers: requestHeaders),
      data: {
        'passenger_id': passengerId,
        'ride_type': typeParam,
        'pickup_latitude': pickupLat,
        'pickup_longitude': pickupLng,
        'pickup_name': pickupName,
        'dropoff_latitude': dropoffLat,
        'dropoff_longitude': dropoffLng,
        'dropoff_name': dropoffName,
        'fare': fare,
      },
    );
    return parseMapResponse(response, 201);
  }

  Future<Map<String, dynamic>?> fetchDriverLocation(String driverId) async {
    final response = await clientDio.get('/telemetry/location/$driverId');
    return parseMapResponse(response, 200);
  }

  Future<List<dynamic>> fetchDriverReviews(
    String driverId, {
    int? page,
    int? limit,
  }) async {
    final queryParams = <String, dynamic>{};
    if (page != null) queryParams['page'] = page;
    if (limit != null) queryParams['limit'] = limit;

    final response = await clientDio.get(
      '/drivers/$driverId/reviews',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    return parseListResponse(response, 200);
  }

  Future<Map<String, dynamic>?> fetchDriverStats(String driverId) async {
    final driverStatsResponse = await clientDio.get('/drivers/$driverId/stats');
    return parseMapResponse(driverStatsResponse, 200);
  }

  Future<List<dynamic>> fetchOnlineDrivers() async {
    final response = await clientDio.get('/drivers/online');
    return parseListResponse(response, 200);
  }

  Future<Map<String, dynamic>?> getDriverProfile(String driverId) async {
    final response = await clientDio.get('/drivers/$driverId');
    return parseMapResponse(response, 200);
  }

  Future<Map<String, dynamic>?> getRideStatus(String rideId) async {
    final response = await clientDio.get('/rides/$rideId');
    return parseMapResponse(response, 200);
  }

  Future<Map<String, dynamic>?> submitDriverReview({
    required String driverId,
    required String passengerName,
    required double rating,
    required String comment,
  }) async {
    final response = await clientDio.post(
      '/drivers/$driverId/reviews',
      data: {
        'passengerName': passengerName,
        'rating': rating,
        'comment': comment,
      },
    );
    return parseMapResponse(response, 201);
  }

  Future<bool> updateLocation({
    required String rideId,
    required double lat,
    required double lng,
  }) async {
    final response = await clientDio.post(
      '/telemetry/location',
      data: {'driverId': rideId, 'lat': lat, 'lng': lng},
    );
    return parseBoolResponse(response, 200);
  }

  Future<bool> updateRideStatus(String rideId, String status) async {
    final response = await clientDio.post(
      '/rides/$rideId/status',
      data: {'status': status},
    );
    return parseBoolResponse(response, 200);
  }

  Future<Map<String, String>> _getRequestHeaders() async {
    final String jsonWebToken = await _sessionService.readAuthToken() ?? '';
    final Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
    };
    if (jsonWebToken.isNotEmpty) {
      requestHeaders['Authorization'] = 'Bearer $jsonWebToken';
    }
    return requestHeaders;
  }
}
