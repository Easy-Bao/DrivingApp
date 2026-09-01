import 'package:dio/dio.dart';

abstract class DriverAvailabilityRemoteDataSource {
  Future<void> updateOnlineStatus({
    required String driverId,
    required bool isOnline,
  });
}

class DriverAvailabilityRemoteDataSourceImpl(this._dio)
    implements DriverAvailabilityRemoteDataSource {
  final Dio _dio;

  @override
  Future<void> updateOnlineStatus({
    required String driverId,
    required bool isOnline,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/api/v1/drivers/${Uri.encodeComponent(driverId)}/online',
      data: {'is_online': isOnline},
    );
  }
}
