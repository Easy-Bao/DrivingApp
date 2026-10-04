import 'package:dio/dio.dart';

abstract class RideRemoteDataSource {
  Future<bool> acceptRide({required String tripId, required String driverId});

  Future<Map<String, dynamic>> markArrived({
    required String rideId,
    required double latitude,
    required double longitude,
  });

  Future<Map<String, dynamic>> startRide({
    required String rideId,
    required double latitude,
    required double longitude,
  });

  Future<Map<String, dynamic>> completeRide({
    required String rideId,
    required double latitude,
    required double longitude,
  });

  Future<Map<String, dynamic>> markPassengerNoShow(String rideId);

  Future<Map<String, dynamic>> createSafetyReport({
    required String rideId,
    required String category,
    required String description,
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
  Future<Map<String, dynamic>> markArrived({
    required String rideId,
    required double latitude,
    required double longitude,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/rides/${Uri.encodeComponent(rideId)}/arrived',
      data: {'latitude': latitude, 'longitude': longitude},
    );
    return response.data ?? const <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> markPassengerNoShow(String rideId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/rides/${Uri.encodeComponent(rideId)}/no-show',
    );
    return response.data ?? const <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> createSafetyReport({
    required String rideId,
    required String category,
    required String description,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/rides/${Uri.encodeComponent(rideId)}/reports',
      data: {'category': category, 'description': description},
    );
    return response.data ?? const <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> startRide({
    required String rideId,
    required double latitude,
    required double longitude,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/rides/${Uri.encodeComponent(rideId)}/start',
      data: {'latitude': latitude, 'longitude': longitude},
    );
    return response.data ?? const <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> completeRide({
    required String rideId,
    required double latitude,
    required double longitude,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/rides/${Uri.encodeComponent(rideId)}/complete',
      data: {'latitude': latitude, 'longitude': longitude},
    );
    return response.data ?? const <String, dynamic>{};
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
