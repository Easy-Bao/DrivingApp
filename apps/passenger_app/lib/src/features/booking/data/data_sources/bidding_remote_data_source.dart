import 'package:dio/dio.dart';

abstract class BiddingRemoteDataSource {
  Future<Map<String, dynamic>> requestRide(Map<String, dynamic> body);
  Future<List<dynamic>> fetchOffers(String sessionId);
  Future<bool> acceptOffer({
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
  Future<Map<String, dynamic>?> getRideStatus(String rideId);
  Future<Map<String, dynamic>?> fetchDriverLocation(String driverId);
  Future<bool> updateRideStatus(String rideId, String status);
  Future<bool> submitDriverReview({
    required String driverId,
    required String passengerName,
    required double rating,
    required String comment,
  });
  Future<Map<String, dynamic>> getDriverProfile(String driverId);
}

class BiddingRemoteDataSourceImpl implements BiddingRemoteDataSource {
  final Dio _dio;

  BiddingRemoteDataSourceImpl(this._dio);

  @override
  Future<Map<String, dynamic>> requestRide(Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/bids/session',
      data: body,
    );
    return response.data ?? {};
  }

  @override
  Future<List<dynamic>> fetchOffers(String sessionId) async {
    final response = await _dio.get<List<dynamic>>(
      '/bids/session/$sessionId/offers',
    );
    return response.data ?? [];
  }

  @override
  Future<bool> acceptOffer({
    required String sessionId,
    required String offerId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/bids/session/$sessionId/accept',
      data: {'offer_id': offerId},
    );
    return response.statusCode == 200;
  }

  @override
  Future<bool> cancelSession(String sessionId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/bids/session/$sessionId/cancel',
    );
    return response.statusCode == 200;
  }

  @override
  Future<Map<String, dynamic>> fetchDriverStats(String driverId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/drivers/$driverId/stats',
    );
    return response.data ?? {};
  }

  @override
  Future<List<dynamic>> fetchDriverReviews(
    String driverId, {
    int? page,
    int? limit,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/drivers/$driverId/reviews',
      queryParameters: {'page': ?page, 'limit': ?limit},
    );
    return response.data ?? [];
  }

  @override
  Future<List<dynamic>> fetchOnlineDrivers() async {
    final response = await _dio.get<List<dynamic>>('/drivers/online');
    return response.data ?? [];
  }

  @override
  Future<Map<String, dynamic>?> getRideStatus(String rideId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/bids/rides/$rideId/status',
    );
    return response.data;
  }

  @override
  Future<Map<String, dynamic>?> fetchDriverLocation(String driverId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/telemetry/driver/$driverId/location',
    );
    return response.data;
  }

  @override
  Future<bool> updateRideStatus(String rideId, String status) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/bids/rides/$rideId/status',
      data: {'status': status},
    );
    return response.statusCode == 200;
  }

  @override
  Future<bool> submitDriverReview({
    required String driverId,
    required String passengerName,
    required double rating,
    required String comment,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/drivers/$driverId/reviews',
      data: {
        'passenger_name': passengerName,
        'rating': rating,
        'comment': comment,
      },
    );
    return response.statusCode == 200;
  }

  @override
  Future<Map<String, dynamic>> getDriverProfile(String driverId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/drivers/$driverId/profile',
    );
    return response.data ?? {};
  }
}
