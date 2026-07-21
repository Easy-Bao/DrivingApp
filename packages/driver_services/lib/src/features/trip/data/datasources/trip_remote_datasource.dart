import 'package:driver_services/src/core/network/base_api_client.dart';

abstract class TripRemoteDataSource {
  Future<List<dynamic>> fetchTripHistory(String driverId);

  Future<Map<String, dynamic>> fetchStats(String driverId);

  Future<Map<String, dynamic>> getRideStatus(String rideId);

  Future<bool> acceptRide({
    required String rideId,
    required String driverId,
    required String driverName,
    required String driverRating,
    required String vehicleType,
    required String plateNumber,
  });

  Future<bool> updateRideStatus(String rideId, String status);
}

class TripRemoteDataSourceImpl extends BaseApiClient implements TripRemoteDataSource {
  TripRemoteDataSourceImpl({required super.baseUrl, super.dio});

  @override
  Future<List<dynamic>> fetchTripHistory(String driverId) async {
    final response = await clientDio.get('/drivers/$driverId/trips');
    return parseListResponse(response, 200);
  }

  @override
  Future<Map<String, dynamic>> fetchStats(String driverId) async {
    final response = await clientDio.get('/drivers/$driverId/stats');
    return parseMapResponse(response, 200);
  }

  @override
  Future<Map<String, dynamic>> getRideStatus(String rideId) async {
    final response = await clientDio.get('/rides/$rideId');
    return parseMapResponse(response, 200);
  }

  @override
  Future<bool> acceptRide({
    required String rideId,
    required String driverId,
    required String driverName,
    required String driverRating,
    required String vehicleType,
    required String plateNumber,
  }) async {
    final response = await clientDio.post(
      '/rides/$rideId/accept',
      data: {
        'driver_id': driverId,
        'driver_name': driverName,
        'driver_rating': driverRating,
        'vehicle_type': vehicleType,
        'plate_number': plateNumber,
      },
    );
    return parseBoolResponse(response, 200);
  }

  @override
  Future<bool> updateRideStatus(String rideId, String status) async {
    final response = await clientDio.post(
      '/rides/$rideId/status',
      data: {'status': status},
    );
    return parseBoolResponse(response, 200);
  }
}
