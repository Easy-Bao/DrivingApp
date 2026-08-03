import 'package:dio/dio.dart';

abstract class TripRemoteDataSource {
  Future<bool> acceptRide({required String tripId, required String driverId});
  Future<bool> updateRideStatus({
    required String tripId,
    required String status,
  });
  Future<Map<String, dynamic>> fetchTripDetails(String tripId);
  Future<Map<String, dynamic>> getRideStatus(String tripId);
  Future<Map<String, dynamic>> fetchStats(String driverId);
  Future<List<dynamic>> fetchTripHistory(String driverId);
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
      '/rides/$tripId/accept',
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
      '/rides/$tripId/status',
      data: {'status': status},
    );
    return response.statusCode == 200;
  }

  @override
  Future<Map<String, dynamic>> fetchTripDetails(String tripId) async {
    final response = await _dio.get<Map<String, dynamic>>('/rides/$tripId');
    return response.data ?? {};
  }

  @override
  Future<Map<String, dynamic>> getRideStatus(String tripId) async {
    final response = await _dio.get<Map<String, dynamic>>('/rides/$tripId');
    return response.data ?? {};
  }

  @override
  Future<Map<String, dynamic>> fetchStats(String driverId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/drivers/$driverId/stats',
    );
    return response.data ?? {};
  }

  @override
  Future<List<dynamic>> fetchTripHistory(String driverId) async {
    final response = await _dio.get<List<dynamic>>('/drivers/$driverId/trips');
    return response.data ?? [];
  }
}
