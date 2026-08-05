import 'package:dio/dio.dart';

abstract class DriverRemoteDataSource {
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
  Future<void> updateOnlineStatus({
    required String driverId,
    required bool isOnline,
    required double lat,
    required double lng,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/api/v1/drivers/$driverId/online',
      data: {'isOnline': isOnline, 'lat': lat, 'lng': lng},
    );
  }
}
