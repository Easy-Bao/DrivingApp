import 'package:driver_services/src/core/network/base_api_client.dart';

abstract class TelemetryRemoteDataSource {
  Future<bool> updateLocation({
    required String driverId,
    required double lat,
    required double lng,
  });

  Future<Map<String, dynamic>> fetchPassengerLocation(String rideId);
}

class TelemetryRemoteDataSourceImpl extends BaseApiClient implements TelemetryRemoteDataSource {
  TelemetryRemoteDataSourceImpl({required super.baseUrl, super.dio});

  @override
  Future<bool> updateLocation({
    required String driverId,
    required double lat,
    required double lng,
  }) async {
    final response = await clientDio.post(
      '/telemetry/location',
      data: {'driverId': driverId, 'lat': lat, 'lng': lng},
    );
    return parseBoolResponse(response, 200);
  }

  @override
  Future<Map<String, dynamic>> fetchPassengerLocation(String rideId) async {
    final response = await clientDio.get('/telemetry/location/$rideId');
    return parseMapResponse(response, 200);
  }
}
