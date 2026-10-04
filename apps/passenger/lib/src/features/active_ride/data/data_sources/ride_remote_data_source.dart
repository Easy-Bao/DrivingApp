import 'package:dio/dio.dart';

abstract class RideRemoteDataSource {
  Future<Map<String, dynamic>?> fetchRide(String rideId);

  Future<Map<String, dynamic>?> fetchDriverLocation(String rideId);

  Future<bool> sendPassengerLocation({
    required String rideId,
    required double latitude,
    required double longitude,
  });

  Future<bool> updateStatus(String rideId, String status);

  Future<bool> cancelRide({
    required String rideId,
    required String reason,
    String details = '',
  });

  Future<Map<String, dynamic>> emergencyStop({
    required String rideId,
    required String reason,
    String details = '',
  });

  Future<Map<String, dynamic>> createSafetyReport({
    required String rideId,
    required String category,
    required String description,
  });

  Future<Map<String, dynamic>> fetchCounterparty(String rideId);
}

class RideRemoteDataSourceImpl(this._dio) implements RideRemoteDataSource {
  final Dio _dio;

  @override
  Future<Map<String, dynamic>?> fetchRide(String rideId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/rides/${Uri.encodeComponent(rideId)}',
    );
    return response.data;
  }

  @override
  Future<Map<String, dynamic>?> fetchDriverLocation(String rideId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/telemetry/rides/${Uri.encodeComponent(rideId)}/driver',
    );
    return response.data;
  }

  @override
  Future<bool> sendPassengerLocation({
    required String rideId,
    required double latitude,
    required double longitude,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/telemetry/passenger/${Uri.encodeComponent(rideId)}',
      data: {'latitude': latitude, 'longitude': longitude},
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  @override
  Future<bool> updateStatus(String rideId, String status) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/rides/${Uri.encodeComponent(rideId)}/status',
      data: {'status': status},
    );
    return response.statusCode == 200;
  }

  @override
  Future<bool> cancelRide({
    required String rideId,
    required String reason,
    String details = '',
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/rides/${Uri.encodeComponent(rideId)}/cancel',
      data: {'reason': reason, 'details': details},
    );
    return response.statusCode == 200;
  }

  @override
  Future<Map<String, dynamic>> emergencyStop({
    required String rideId,
    required String reason,
    String details = '',
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/rides/${Uri.encodeComponent(rideId)}/emergency-stop',
      data: {'reason': reason, 'details': details},
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
  Future<Map<String, dynamic>> fetchCounterparty(String rideId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/rides/${Uri.encodeComponent(rideId)}/counterparty',
    );
    return response.data ?? const <String, dynamic>{};
  }
}
