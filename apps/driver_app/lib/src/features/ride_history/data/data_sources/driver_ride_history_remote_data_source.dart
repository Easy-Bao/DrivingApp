import 'package:dio/dio.dart';
import 'package:foundation/foundation.dart';

abstract class DriverRideHistoryRemoteDataSource {
  Future<OffsetPage<Map<String, dynamic>>> fetchTripHistory(
    String driverId, {
    int limit = 25,
    int offset = 0,
    bool activeOnly = false,
  });
}

class DriverRideHistoryRemoteDataSourceImpl
    implements DriverRideHistoryRemoteDataSource {
  DriverRideHistoryRemoteDataSourceImpl(this._dio);

  final Dio _dio;

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
