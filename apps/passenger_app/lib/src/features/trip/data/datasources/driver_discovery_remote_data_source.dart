import 'package:dio/dio.dart';

abstract class DriverDiscoveryRemoteDataSource {
  Future<List<dynamic>> fetchOnlineDrivers(List<String> driverIds);

  Future<List<dynamic>> fetchNearbyDrivers({
    required double latitude,
    required double longitude,
    double radiusKm,
  });
}

class DriverDiscoveryRemoteDataSourceImpl
    implements DriverDiscoveryRemoteDataSource {
  final Dio _dio;

  DriverDiscoveryRemoteDataSourceImpl(this._dio);

  @override
  Future<List<dynamic>> fetchOnlineDrivers(List<String> driverIds) async {
    if (driverIds.isEmpty || driverIds.length > 20) {
      throw const FormatException('Nearby driver identifiers are invalid.');
    }
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/drivers/online',
      queryParameters: {'ids': driverIds.join(',')},
    );
    return response.data ?? const <dynamic>[];
  }

  @override
  Future<List<dynamic>> fetchNearbyDrivers({
    required double latitude,
    required double longitude,
    double radiusKm = 5,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/telemetry/location/nearby',
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'radius_km': radiusKm,
      },
    );
    final drivers = response.data?['drivers'];
    return drivers is List ? List<dynamic>.from(drivers) : const <dynamic>[];
  }
}
