import 'package:dio/dio.dart';
import 'package:foundation/foundation.dart';

abstract class DriverActivityRemoteDataSource {
  Future<Map<String, dynamic>> fetchStats(String driverId);

  Future<Map<String, dynamic>> fetchEarningsSummary(String driverId);

  Future<OffsetPage<Map<String, dynamic>>> fetchTripHistory(
    String driverId, {
    int limit = 25,
    int offset = 0,
    bool activeOnly = false,
  });
}

class DriverActivityRemoteDataSourceImpl
    implements DriverActivityRemoteDataSource {
  final Dio _dio;

  DriverActivityRemoteDataSourceImpl(this._dio);

  @override
  Future<Map<String, dynamic>> fetchStats(String driverId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/drivers/${Uri.encodeComponent(driverId)}/stats',
    );
    return response.data ?? const <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> fetchEarningsSummary(String driverId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/drivers/${Uri.encodeComponent(driverId)}/earnings',
    );
    return response.data ?? const <String, dynamic>{};
  }

  @override
  Future<OffsetPage<Map<String, dynamic>>> fetchTripHistory(
    String driverId, {
    int limit = 25,
    int offset = 0,
    bool activeOnly = false,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/drivers/${Uri.encodeComponent(driverId)}/trips',
      queryParameters: {
        'limit': limit,
        'offset': offset,
        if (activeOnly) 'scope': 'active',
      },
    );
    return OffsetPage<Map<String, dynamic>>.fromJson(
      response.data ?? const <String, dynamic>{},
      (value) =>
          decodeObjectMap(value, message: 'Driver trip item is invalid.'),
    );
  }
}
