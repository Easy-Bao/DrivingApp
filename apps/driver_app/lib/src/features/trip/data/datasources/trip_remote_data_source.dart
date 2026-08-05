import 'package:dio/dio.dart';

abstract class TripRemoteDataSource {
  Future<bool> acceptRide({required String tripId, required String driverId});
  Future<bool> updateRideStatus({
    required String tripId,
    required String status,
  });
  Future<Map<String, dynamic>> fetchTripDetails(String tripId);
  Future<Map<String, dynamic>> getRideStatus(String tripId);
  Future<Map<String, dynamic>> settleCash(String tripId);
  Future<bool> submitPassengerReview({
    required String passengerId,
    required String rideId,
    required double rating,
    required String comment,
  });
  Future<Map<String, dynamic>> fetchStats(String driverId);
  Future<List<dynamic>> fetchTripHistory(String driverId);
}

class TripRemoteDataSourceImpl implements TripRemoteDataSource {
  final Dio _dio;

  TripRemoteDataSourceImpl(this._dio);

  @override
  Future<bool> acceptRide({
    required String tripId,
    required String driverId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/rides/$tripId/accept',
      data: {'driver_id': driverId},
    );
    return response.statusCode == 200;
  }

  @override
  Future<bool> updateRideStatus({
    required String tripId,
    required String status,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/rides/$tripId/status',
      data: {'status': status},
    );
    return response.statusCode == 200;
  }

  @override
  Future<Map<String, dynamic>> fetchTripDetails(String tripId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/rides/$tripId',
    );
    return response.data ?? {};
  }

  @override
  Future<Map<String, dynamic>> getRideStatus(String tripId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/rides/$tripId',
    );
    return response.data ?? {};
  }

  @override
  Future<Map<String, dynamic>> settleCash(String tripId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/rides/$tripId/cash-settle',
    );
    return response.data ?? {};
  }

  @override
  Future<bool> submitPassengerReview({
    required String passengerId,
    required String rideId,
    required double rating,
    required String comment,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/passengers/$passengerId/reviews',
      data: {
        'ride_id': int.tryParse(rideId),
        'rating': rating,
        'comment': comment,
      },
    );
    return response.statusCode == 201 || response.statusCode == 200;
  }

  @override
  Future<Map<String, dynamic>> fetchStats(String driverId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/drivers/$driverId/stats',
    );
    return response.data ?? {};
  }

  @override
  Future<List<dynamic>> fetchTripHistory(String driverId) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/drivers/$driverId/trips',
    );
    return response.data ?? [];
  }
}
