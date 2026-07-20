import 'package:driver_services/src/base_api_client.dart';

class BiddingApiService extends BaseApiClient {
  BiddingApiService({required super.baseUrl, super.dio});

  Future<Map<String, dynamic>?> fetchFareEstimate({
    required double distanceKm,
    required double durationMinutes,
    String rideType = 'Solo Ride',
  }) async {
    try {
      final response = await clientDio.post(
        '/bids/fare',
        data: {
          'ride_type': rideType,
          'distance_km': distanceKm,
          'duration_minutes': durationMinutes,
        },
      );
      return parseMapResponse(response, 200);
    } catch (_) {
      return null;
    }
  }

  Future<List<dynamic>> fetchActiveBids(String driverId) async {
    try {
      final response = await clientDio.get(
        '/bids/active',
        queryParameters: {'driver_id': driverId},
      );
      return parseListResponse(response, 200);
    } catch (_) {
      return [];
    }
  }

  Future<bool> placeBid({
    required String sessionId,
    required String driverId,
    required String driverName,
    required String plateNumber,
    required String vehicleType,
    double? proposedFare,
  }) async {
    try {
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
    } catch (_) {
      return false;
    }
  }

  Future<bool> cancelBid({
    required String sessionId,
    required String driverId,
  }) async {
    try {
      final response = await clientDio.post(
        '/bids/$sessionId/cancel-offer',
        data: {'driver_id': driverId},
      );
      return parseBoolResponse(response, 200);
    } catch (_) {
      return false;
    }
  }
}
