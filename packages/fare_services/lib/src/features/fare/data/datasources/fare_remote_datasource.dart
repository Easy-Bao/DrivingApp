import 'package:fare_services/src/core/network/base_api_client.dart';

abstract class FareRemoteDataSource {
  Future<Map<String, dynamic>> fetchFareQuote({
    required double distanceKm,
    required double durationMinutes,
    String rideType = 'Solo Ride',
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
      '/bids/fare',
      data: {
        'ride_type': rideType,
        'distance_km': distanceKm,
        'duration_minutes': durationMinutes,
      },
    );
    return parseMapResponse(response, 200);
  }
}
