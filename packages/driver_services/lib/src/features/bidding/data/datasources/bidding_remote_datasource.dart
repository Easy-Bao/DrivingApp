import 'package:driver_services/src/core/network/base_api_client.dart';

abstract class BiddingRemoteDataSource {
  Future<Map<String, dynamic>> fetchFareEstimate({
    required double distanceKm,
    required double durationMinutes,
    String rideType = 'Solo Ride',
  });

  Future<List<dynamic>> fetchActiveBids(String driverId);

  Future<bool> placeBid({
    required String sessionId,
    required String driverId,
    required String driverName,
    required String plateNumber,
    required String vehicleType,
    double? proposedFare,
  });

  Future<bool> cancelBid({
    required String sessionId,
    required String driverId,
  });
}

class BiddingRemoteDataSourceImpl extends BaseApiClient implements BiddingRemoteDataSource {
  BiddingRemoteDataSourceImpl({required super.baseUrl, super.dio});

  @override
  Future<Map<String, dynamic>> fetchFareEstimate({
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

  @override
  Future<List<dynamic>> fetchActiveBids(String driverId) async {
    final response = await clientDio.get(
      '/bids/active',
      queryParameters: {'driver_id': driverId},
    );
    return parseListResponse(response, 200);
  }

  @override
  Future<bool> placeBid({
    required String sessionId,
    required String driverId,
    required String driverName,
    required String plateNumber,
    required String vehicleType,
    double? proposedFare,
  }) async {
    final Map<String, dynamic> bodyData = {
      'driver_id': driverId,
      'driver_name': driverName,
      'plate_number': plateNumber,
      'vehicle_type': vehicleType,
    };
    if (proposedFare != null) {
      bodyData['proposed_fare'] = proposedFare;
    }
    final response = await clientDio.post(
      '/bids/$sessionId/offer',
      data: bodyData,
    );
    return parseBoolResponse(response, 201);
  }

  @override
  Future<bool> cancelBid({
    required String sessionId,
    required String driverId,
  }) async {
    final response = await clientDio.post(
      '/bids/$sessionId/cancel-offer',
      data: {'driver_id': driverId},
    );
    return parseBoolResponse(response, 200);
  }
}
