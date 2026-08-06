import 'package:dio/dio.dart';

abstract class TelemetryRemoteDataSource {
  Future<bool> sendLocationUpdate({
    required String driverId,
    required double lat,
    required double lng,
    double? heading,
    double? speed,
  });
  Future<bool> removeLocation();
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
      '/api/v1/telemetry/location',
      data: {
        'driverId': driverId,
        'lat': lat,
        'lng': lng,
        'heading': ?heading,
        'speed': ?speed,
      },
    );
    return response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 202;
  }

  @override
  Future<bool> removeLocation() async {
    final response = await _dio.delete<void>('/api/v1/telemetry/location');
    return response.statusCode == 200 || response.statusCode == 204;
  }

  @override
  Future<Map<String, dynamic>> fetchPassengerLocation(String tripId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/telemetry/passenger/$tripId',
      );
      return response.data ?? {};
    } catch (_) {
      return {};
    }
  }
}
