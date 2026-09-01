import 'package:dio/dio.dart';

abstract class RideOfferRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchActiveBids();

  Future<bool> placeBid({
    required String sessionId,
    required double offerPrice,
    String? driverName,
    String? plateNumber,
    String? vehicleType,
  });
}

class RideOfferRemoteDataSourceImpl(this._dio)
    implements RideOfferRemoteDataSource {
  final Dio _dio;

  @override
  Future<List<Map<String, dynamic>>> fetchActiveBids() async {
    final response = await _dio.get<List<dynamic>>('/api/v1/bids/active');
    return [
      for (final item in response.data ?? const <dynamic>[])
        if (item is Map) Map<String, dynamic>.from(item),
    ];
  }

  @override
  Future<bool> placeBid({
    required String sessionId,
    required double offerPrice,
    String? driverName,
    String? plateNumber,
    String? vehicleType,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/bids/${Uri.encodeComponent(sessionId)}/offer',
      data: {
        'proposed_fare_centavos': (offerPrice * 100).round(),
        'driver_name': ?driverName,
        'plate_number': ?plateNumber,
        'vehicle_type': ?vehicleType,
      },
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }
}
