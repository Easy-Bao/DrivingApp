import 'package:dio/dio.dart';

abstract class DriverAvailabilityRemoteDataSource {
  Future<void> updateOnlineStatus({
    required String driverId,
    required bool isOnline,
    required double lat,
    required double lng,
  });
}

class DriverAvailabilityRemoteDataSourceImpl
    implements DriverAvailabilityRemoteDataSource {
  final Dio _dio;

  DriverAvailabilityRemoteDataSourceImpl(this._dio);

  @override
  Future<void> updateOnlineStatus({
    required String driverId,
    required bool isOnline,
    required double lat,
    required double lng,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/api/v1/drivers/${Uri.encodeComponent(driverId)}/online',
      data: {'is_online': isOnline, 'lat': lat, 'lng': lng},
    );
  }
}
