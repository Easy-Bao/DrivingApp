import 'package:dio/dio.dart';
import 'package:shared_core/shared_core.dart';

abstract class TripRemoteDataSource {
  Future<bool> acceptRide({required String tripId, required String driverId});
  Future<bool> updateRideStatus({
    required String tripId,
    required String status,
  });
  Future<Map<String, dynamic>> fetchTripDetails(String tripId);
  Future<Map<String, dynamic>> getRideStatus(String tripId);
  Future<Map<String, dynamic>> settleCash(String tripId);
  Future<Map<String, dynamic>> fetchStats(String driverId);
  Future<Map<String, dynamic>> fetchEarningsSummary(String driverId);
  Future<OffsetPage<Map<String, dynamic>>> fetchTripHistory(
    String driverId, {
    int limit = 25,
    int offset = 0,
    bool activeOnly = false,
  });
}

class TripRemoteDataSourceImpl implements TripRemoteDataSource {
  final Dio _dio;

  TripRemoteDataSourceImpl(this._dio);

  @override
  Future<bool> acceptRide({
    required String tripId,
    required String driverId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/rides/$tripId/accept',
      data: {'driver_id': driverId},
    );
    return response.statusCode == 200;
  }

  @override
  Future<bool> updateRideStatus({
    required String tripId,
    required String status,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/rides/$tripId/status',
      data: {'status': status},
    );
    return response.statusCode == 200;
  }

  @override
  Future<Map<String, dynamic>> fetchTripDetails(String tripId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/rides/$tripId',
    );
    return response.data ?? {};
  }

  @override
  Future<Map<String, dynamic>> getRideStatus(String tripId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/rides/$tripId',
    );
    return response.data ?? {};
  }

  @override
  Future<Map<String, dynamic>> settleCash(String tripId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/rides/$tripId/cash-settle',
    );
    return response.data ?? {};
  }

  @override
  Future<Map<String, dynamic>> fetchStats(String driverId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/drivers/$driverId/stats',
    );
    return response.data ?? {};
  }

  @override
  Future<Map<String, dynamic>> fetchEarningsSummary(String driverId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/drivers/$driverId/earnings',
    );
    return response.data ?? {};
  }

  @override
  Future<OffsetPage<Map<String, dynamic>>> fetchTripHistory(
    String driverId, {
    int limit = 25,
    int offset = 0,
    bool activeOnly = false,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/drivers/$driverId/trips',
      queryParameters: {
        'limit': limit,
        'offset': offset,
        if (activeOnly) 'scope': 'active',
      },
    );
    return OffsetPage<Map<String, dynamic>>.fromJson(
      response.data ?? const <String, dynamic>{},
      (value) => Map<String, dynamic>.from(value! as Map),
    );
  }
}
