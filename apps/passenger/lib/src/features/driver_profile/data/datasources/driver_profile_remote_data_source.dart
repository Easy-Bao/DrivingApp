import 'package:dio/dio.dart';
import 'package:foundation/foundation.dart';

abstract class DriverProfileRemoteDataSource {
  Future<Map<String, dynamic>> fetchStats(String driverId);

  Future<OffsetPage<Map<String, dynamic>>> fetchReviews(
    String driverId, {
    int page = 1,
    String? cursor = '',
    int limit = 20,
  });

  Future<Map<String, dynamic>?> fetchMyRideReview(String rideId);

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
  Future<OffsetPage<Map<String, dynamic>>> fetchReviews(
    String driverId, {
    int page = 1,
    String? cursor = '',
    int limit = 20,
  }) async {
    if (page < 1 || limit < 1 || limit > 100) {
      throw const FormatException('Driver review page is invalid.');
    }
    final response = await _dio.get<Object?>(
      '/api/v1/drivers/${Uri.encodeComponent(driverId)}/reviews',
      queryParameters: {
        if (cursor != null) 'cursor': cursor else 'offset': (page - 1) * limit,
        'limit': limit,
      },
    );
    final data = response.data;
    if (data is Map) {
      return OffsetPage<Map<String, dynamic>>.fromJson(
        decodeObjectMap(data),
        (value) => decodeObjectMap(value),
      );
    }
    // Older servers ignore cursor and return an array. Continue their offset
    // contract until server rollout is complete.
    if (data is! List) {
      throw const FormatException('Driver reviews are invalid.');
    }
    final hasMore = data.length >= limit;
    return OffsetPage<Map<String, dynamic>>(
      items: [
        for (final item in data)
          if (item is Map) decodeObjectMap(item),
      ],
      hasMore: hasMore,
      nextOffset: hasMore ? page * limit : null,
    );
  }

  @override
  Future<Map<String, dynamic>?> fetchMyRideReview(String rideId) async {
    final parsedRideId = int.tryParse(rideId);
    if (parsedRideId == null || parsedRideId <= 0) {
      throw const FormatException('Ride identifier is invalid.');
    }
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/rides/${Uri.encodeComponent(rideId)}/my-review',
    );
    return response.data;
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
