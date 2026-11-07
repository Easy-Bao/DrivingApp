import 'package:dio/dio.dart';

abstract class AvailabilityRemoteDataSource {
  Future<void> updateOnlineStatus({
    required String driverId,
    required bool isOnline,
  });
}

class AvailabilityRemoteDataSourceImpl(this._dio)
    implements AvailabilityRemoteDataSource {
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
