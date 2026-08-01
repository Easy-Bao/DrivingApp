import 'package:dio/dio.dart';

abstract class TelemetryRemoteDataSource {
  Future<bool> sendLocationUpdate({
    required String driverId,
    required double lat,
    required double lng,
    double? heading,
    double? speed,
  });
  Future<Map<String, dynamic>> fetchPassengerLocation(String tripId);
}

class TelemetryRemoteDataSourceImpl implements TelemetryRemoteDataSource {
  final Dio _dio;

  TelemetryRemoteDataSourceImpl(this._dio);

  @override
  Future<bool> sendLocationUpdate({
    required String driverId,
    required double lat,
    required double lng,
    double? heading,
    double? speed,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/telemetry/location',
      data: {
        'driver_id': driverId,
        'latitude': lat,
        'longitude': lng,
        if (heading != null) 'heading': heading,
        if (speed != null) 'speed': speed,
      },
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  @override
  Future<Map<String, dynamic>> fetchPassengerLocation(String tripId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/telemetry/passenger/$tripId',
      );
      return response.data ?? {};
    } catch (_) {
      return {};
    }
  }
}
