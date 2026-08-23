import 'package:dio/dio.dart';

abstract class RideCounterpartyRemoteDataSource {
  Future<Map<String, dynamic>> fetch(String rideId);
}

class RideCounterpartyRemoteDataSourceImpl
    implements RideCounterpartyRemoteDataSource {
  final Dio _dio;

  RideCounterpartyRemoteDataSourceImpl(this._dio);

  @override
  Future<Map<String, dynamic>> fetch(String rideId) async {
    final normalizedRideId = rideId.trim();
    if (normalizedRideId.isEmpty) {
      throw const FormatException('Ride ID is required.');
    }
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/rides/${Uri.encodeComponent(normalizedRideId)}/counterparty',
    );
    return response.data ?? const <String, dynamic>{};
  }
}
