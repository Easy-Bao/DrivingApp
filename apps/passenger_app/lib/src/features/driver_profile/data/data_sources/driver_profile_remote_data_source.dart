import 'package:dio/dio.dart';

abstract class DriverProfileRemoteDataSource {
  Future<Map<String, dynamic>> fetchStats(String driverId);

  Future<List<Map<String, dynamic>>> fetchReviews(
    String driverId, {
    int page = 1,
    int limit = 20,
  });

  Future<bool> submitReview({
    required String driverId,
    required String rideId,
    required double rating,
    required String comment,
  });
}

class DriverProfileRemoteDataSourceImpl(this._dio)
    implements DriverProfileRemoteDataSource {
  final Dio _dio;

  @override
  Future<Map<String, dynamic>> fetchStats(String driverId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/drivers/${Uri.encodeComponent(driverId)}/stats',
    );
    return response.data ?? const <String, dynamic>{};
  }

  @override
  Future<List<Map<String, dynamic>>> fetchReviews(
    String driverId, {
    int page = 1,
    int limit = 20,
  }) async {
    if (page < 1 || limit < 1 || limit > 100) {
      throw const FormatException('Driver review page is invalid.');
    }
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/drivers/${Uri.encodeComponent(driverId)}/reviews',
      queryParameters: {'offset': (page - 1) * limit, 'limit': limit},
    );
    return [
      for (final item in response.data ?? const <dynamic>[])
        if (item is Map) Map<String, dynamic>.from(item),
    ];
  }

  @override
  Future<bool> submitReview({
    required String driverId,
    required String rideId,
    required double rating,
    required String comment,
  }) async {
    final parsedRideId = int.tryParse(rideId);
    if (parsedRideId == null || parsedRideId <= 0) {
      throw const FormatException('Ride identifier is invalid.');
    }
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/drivers/${Uri.encodeComponent(driverId)}/reviews',
      data: {'ride_id': parsedRideId, 'rating': rating, 'comment': comment},
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }
}
