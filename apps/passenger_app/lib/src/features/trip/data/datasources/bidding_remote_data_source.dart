import 'package:dio/dio.dart';
import 'package:shared_core/shared_core.dart';

abstract class BiddingRemoteDataSource {
  Future<FareServiceModel> fetchPricingConfig();

  Future<FareResult> fetchFareEstimate({
    required double distanceKm,
    required double durationMinutes,
    required String rideType,
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
  });

  Future<Map<String, dynamic>> requestRide(Map<String, dynamic> body);
  Future<List<dynamic>> fetchOffers(String sessionId);
  Future<Map<String, dynamic>> acceptOffer({
    required String sessionId,
    required String offerId,
  });
  Future<bool> cancelSession(String sessionId);
  Future<Map<String, dynamic>> fetchDriverStats(String driverId);
  Future<List<dynamic>> fetchDriverReviews(
    String driverId, {
    int? page,
    int? limit,
  });
  Future<List<dynamic>> fetchOnlineDrivers();
  Future<List<dynamic>> fetchPublicDriverSummaries();
  Future<List<dynamic>> fetchNearbyDrivers({
    required double latitude,
    required double longitude,
    double radiusKm,
  });
  Future<Map<String, dynamic>?> getRideStatus(String rideId);
  Future<Map<String, dynamic>?> fetchDriverLocation(String driverId);
  Future<bool> sendPassengerLocation({
    required String rideId,
    required double lat,
    required double lng,
  });
  Future<bool> updateRideStatus(String rideId, String status);
  Future<bool> submitDriverReview({
    required String driverId,
    required String rideId,
    required double rating,
    required String comment,
  });
  Future<Map<String, dynamic>> getDriverProfile(String driverId);
}

class BiddingRemoteDataSourceImpl implements BiddingRemoteDataSource {
  final Dio _dio;

  BiddingRemoteDataSourceImpl(this._dio);

  @override
  Future<FareServiceModel> fetchPricingConfig() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/fares/configs',
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('Pricing configuration response is empty.');
    }
    return FareServiceModel.fromJson(data);
  }

  @override
  Future<FareResult> fetchFareEstimate({
    required double distanceKm,
    required double durationMinutes,
    required String rideType,
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/bids/fare',
      data: {
        'ride_type': rideType,
        'distance_km': distanceKm,
        'duration_minutes': durationMinutes,
        'origin_latitude': originLatitude,
        'origin_longitude': originLongitude,
        'destination_latitude': destinationLatitude,
        'destination_longitude': destinationLongitude,
      },
    );
    return FareResult.fromJson(response.data ?? const <String, dynamic>{});
  }

  @override
  Future<Map<String, dynamic>> requestRide(Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/bids',
      data: body,
    );
    return response.data ?? {};
  }

  @override
  Future<List<dynamic>> fetchOffers(String sessionId) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/bids/$sessionId/offers',
    );
    return response.data ?? [];
  }

  @override
  Future<Map<String, dynamic>> acceptOffer({
    required String sessionId,
    required String offerId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/bids/$sessionId/offers/$offerId/accept',
      data: {'offer_id': offerId},
    );
    return response.data ?? {};
  }

  @override
  Future<bool> cancelSession(String sessionId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/bids/$sessionId/cancel',
    );
    return response.statusCode == 201 || response.statusCode == 200;
  }

  @override
  Future<Map<String, dynamic>> fetchDriverStats(String driverId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/drivers/$driverId/stats',
    );
    return response.data ?? {};
  }

  @override
  Future<List<dynamic>> fetchDriverReviews(
    String driverId, {
    int? page,
    int? limit,
  }) async {
    final pageSize = limit ?? 20;
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/drivers/$driverId/reviews',
      queryParameters: {
        'offset': page == null ? null : (page - 1).clamp(0, 100) * pageSize,
        'limit': ?limit,
      },
    );
    return response.data ?? [];
  }

  @override
  Future<List<dynamic>> fetchOnlineDrivers() async {
    final response = await _dio.get<List<dynamic>>('/api/v1/drivers/online');
    return response.data ?? [];
  }

  @override
  Future<List<dynamic>> fetchPublicDriverSummaries() async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/drivers/public/summaries',
      queryParameters: {'limit': 5},
    );
    return response.data ?? [];
  }

  @override
  Future<List<dynamic>> fetchNearbyDrivers({
    required double latitude,
    required double longitude,
    double radiusKm = 5,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/telemetry/location/nearby',
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'radius_km': radiusKm,
      },
    );
    final drivers = response.data?['drivers'];
    return drivers is List ? List<dynamic>.from(drivers) : const [];
  }

  @override
  Future<Map<String, dynamic>?> getRideStatus(String rideId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/rides/$rideId',
    );
    return response.data;
  }

  @override
  Future<Map<String, dynamic>?> fetchDriverLocation(String driverId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/telemetry/location/$driverId',
    );
    return response.data;
  }

  @override
  Future<bool> sendPassengerLocation({
    required String rideId,
    required double lat,
    required double lng,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/telemetry/passenger/$rideId',
      data: {'lat': lat, 'lng': lng},
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  @override
  Future<bool> updateRideStatus(String rideId, String status) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/rides/$rideId/status',
      data: {'status': status},
    );
    return response.statusCode == 200;
  }

  @override
  Future<bool> submitDriverReview({
    required String driverId,
    required String rideId,
    required double rating,
    required String comment,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/drivers/$driverId/reviews',
      data: {
        'ride_id': int.tryParse(rideId),
        'rating': rating,
        'comment': comment,
      },
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  @override
  Future<Map<String, dynamic>> getDriverProfile(String driverId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/drivers/$driverId',
    );
    return response.data ?? {};
  }
}
