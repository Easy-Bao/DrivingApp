import 'package:dio/dio.dart';

abstract class RideRemoteDataSource {
  Future<bool> acceptRide({required String tripId, required String driverId});

  Future<bool> updateRideStatus({
    required String tripId,
    required String status,
  });

  Future<Map<String, dynamic>> getRideStatus(String tripId);

  Future<Map<String, dynamic>> settleCash({
    required String rideId,
    required int cashReceivedAmount,
    required int cashChangeAmount,
    required String cashOutcome,
  });
}

class RideRemoteDataSourceImpl(this._dio) implements RideRemoteDataSource {
  final Dio _dio;

  @override
  Future<bool> acceptRide({
    required String tripId,
    required String driverId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/rides/${Uri.encodeComponent(tripId)}/accept',
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
      '/api/v1/rides/${Uri.encodeComponent(tripId)}/status',
      data: {'status': status},
    );
    return response.statusCode == 200;
  }

  @override
  Future<Map<String, dynamic>> getRideStatus(String tripId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/rides/${Uri.encodeComponent(tripId)}',
    );
    return response.data ?? const <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> settleCash({
    required String rideId,
    required int cashReceivedAmount,
    required int cashChangeAmount,
    required String cashOutcome,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/rides/${Uri.encodeComponent(rideId)}/cash-settle',
      data: {
        'cash_received_amount': cashReceivedAmount,
        'cash_change_amount': cashChangeAmount,
        'cash_outcome': cashOutcome,
      },
    );
    return response.data ?? const <String, dynamic>{};
  }
}
