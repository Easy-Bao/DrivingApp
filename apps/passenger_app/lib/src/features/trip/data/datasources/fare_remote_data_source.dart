import 'package:dio/dio.dart';
import 'package:shared_core/shared_core.dart';

abstract class FareRemoteDataSource {
  Future<FareResult> fetchEstimate({
    required double distanceKm,
    required double durationMinutes,
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
  });
}

class FareRemoteDataSourceImpl implements FareRemoteDataSource {
  final Dio _dio;

  FareRemoteDataSourceImpl(this._dio);

  @override
  Future<FareResult> fetchEstimate({
    required double distanceKm,
    required double durationMinutes,
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/bids/fare',
      data: {
        'distance_km': distanceKm,
        'duration_minutes': durationMinutes,
        'origin_latitude': originLatitude,
        'origin_longitude': originLongitude,
        'destination_latitude': destinationLatitude,
        'destination_longitude': destinationLongitude,
      },
    );
    return FareResult.fromJson(response.data ?? const <String, dynamic>{});
  }
}
