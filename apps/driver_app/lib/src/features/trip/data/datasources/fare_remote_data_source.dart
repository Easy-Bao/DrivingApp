import 'package:dio/dio.dart';

abstract class FareRemoteDataSource {
  Future<Map<String, dynamic>> fetchFareEstimate({
    required double distanceKm,
    required double durationMinutes,
  });
}

class FareRemoteDataSourceImpl implements FareRemoteDataSource {
  final Dio _dio;

  FareRemoteDataSourceImpl(this._dio);

  @override
  Future<Map<String, dynamic>> fetchFareEstimate({
    required double distanceKm,
    required double durationMinutes,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/bids/fare',
      data: {'distance_km': distanceKm, 'duration_minutes': durationMinutes},
    );
    return response.data ?? const <String, dynamic>{};
  }
}
