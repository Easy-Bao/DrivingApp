import 'package:fare_services/src/core/network/base_api_client.dart';

abstract class FareRemoteDataSource {
  Future<Map<String, dynamic>> fetchFareQuote({
    required double distanceKm,
    required double durationMinutes,
    String rideType = 'Solo Ride',
  });

  Future<Map<String, dynamic>> fetchFareEstimates({
    required double distanceKm,
    double durationMinutes = 0.0,
  });

  Future<Map<String, dynamic>> fetchPricingConfigs();

  Future<Map<String, dynamic>> calculateFinalFare({
    required String rideId,
    required double distanceKm,
    required double durationMinutes,
    String rideType = 'Solo Ride',
    double surgeMultiplier = 1.0,
  });
}

class FareRemoteDataSourceImpl extends BaseApiClient
    implements FareRemoteDataSource {
  FareRemoteDataSourceImpl({required super.baseUrl, super.dio});

  @override
  Future<Map<String, dynamic>> fetchFareQuote({
    required double distanceKm,
    required double durationMinutes,
    String rideType = 'Solo Ride',
  }) async {
    final response = await clientDio.post(
      '/fares/estimate',
      data: {
        'distanceKm': distanceKm,
        'durationMinutes': durationMinutes,
        'rideType': rideType,
      },
    );
    return parseMapResponse(response, 200);
  }

  @override
  Future<Map<String, dynamic>> fetchFareEstimates({
    required double distanceKm,
    double durationMinutes = 0.0,
  }) async {
    final response = await clientDio.post(
      '/fares/estimate',
      data: {
        'distanceKm': distanceKm,
        'durationMinutes': durationMinutes,
      },
    );
    return parseMapResponse(response, 200);
  }

  @override
  Future<Map<String, dynamic>> fetchPricingConfigs() async {
    final response = await clientDio.get('/fares/configs');
    return parseMapResponse(response, 200);
  }

  @override
  Future<Map<String, dynamic>> calculateFinalFare({
    required String rideId,
    required double distanceKm,
    required double durationMinutes,
    String rideType = 'Solo Ride',
    double surgeMultiplier = 1.0,
  }) async {
    final response = await clientDio.post(
      '/fares/calculate-final',
      data: {
        'rideId': rideId,
        'distanceKm': distanceKm,
        'durationMinutes': durationMinutes,
        'rideType': rideType,
        'surgeMultiplier': surgeMultiplier,
      },
    );
    return parseMapResponse(response, 200);
  }
}
