import 'package:dio/dio.dart';
import 'package:shared_core/shared_core.dart';

abstract class BiddingRemoteDataSource {
  Future<FareServiceModel> fetchPricingConfig();

  Future<Map<String, dynamic>> fetchFareEstimate({
    double? distanceKm,
    double? durationMinutes,
    Map<String, dynamic>? body,
  });
  Future<List<dynamic>> fetchActiveBids();
  Future<bool> placeBid({
    required String sessionId,
    required String driverId,
    required double offerPrice,
    String? driverName,
    String? plateNumber,
    String? vehicleType,
    double? proposedFare,
  });
  Future<bool> cancelBid({required String sessionId, required String driverId});
}

class BiddingRemoteDataSourceImpl implements BiddingRemoteDataSource {
  final Dio _dio;

  BiddingRemoteDataSourceImpl(this._dio);

  @override
  Future<FareServiceModel> fetchPricingConfig() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/fares/configs',
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('Pricing configuration response is empty.');
    }
    return FareServiceModel.fromJson(data);
  }

  @override
  Future<Map<String, dynamic>> fetchFareEstimate({
    double? distanceKm,
    double? durationMinutes,
    Map<String, dynamic>? body,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/bids/fare',
      data:
          body ??
          {'distance_km': distanceKm, 'duration_minutes': durationMinutes},
    );
    return response.data ?? {};
  }

  @override
  Future<List<dynamic>> fetchActiveBids() async {
    final response = await _dio.get<List<dynamic>>('/api/v1/bids/active');
    return response.data ?? [];
  }

  @override
  Future<bool> placeBid({
    required String sessionId,
    required String driverId,
    required double offerPrice,
    String? driverName,
    String? plateNumber,
    String? vehicleType,
    double? proposedFare,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/bids/$sessionId/offer',
      data: {
        'driver_id': driverId,
        'offer_price': offerPrice,
        'driver_name': ?driverName,
        'plate_number': ?plateNumber,
        'vehicle_type': ?vehicleType,
        'proposed_fare': ?proposedFare,
      },
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  @override
  Future<bool> cancelBid({
    required String sessionId,
    required String driverId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/bids/$sessionId/cancel-offer',
      data: {'driver_id': driverId},
    );
    return response.statusCode == 200;
  }
}
