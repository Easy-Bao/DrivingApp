import 'package:dio/dio.dart';

abstract class DriverRemoteDataSource {
  Future<Map<String, dynamic>> fetchDriverProfile(String driverId);

  Future<void> updateOnlineStatus({
    required String driverId,
    required bool isOnline,
    required double lat,
    required double lng,
  });
}

class DriverRemoteDataSourceImpl implements DriverRemoteDataSource {
  final Dio _dio;

  DriverRemoteDataSourceImpl(this._dio);

  @override
  Future<Map<String, dynamic>> fetchDriverProfile(String driverId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/drivers/$driverId',
    );
    return response.data ?? {};
  }

  @override
  Future<void> updateOnlineStatus({
    required String driverId,
    required bool isOnline,
    required double lat,
    required double lng,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/api/v1/drivers/$driverId/online',
      data: {'is_online': isOnline, 'lat': lat, 'lng': lng},
    );
  }
}
