import 'package:dio/dio.dart';
import 'package:foundation/foundation.dart';

abstract class PassengerRideHistoryRemoteDataSource {
  Future<OffsetPage<Map<String, dynamic>>> fetchRideHistory(
    String passengerId, {
    int limit = 25,
    int offset = 0,
  });

  Future<Map<String, dynamic>> fetchSummary(String passengerId);
}

class PassengerRideHistoryRemoteDataSourceImpl
    implements PassengerRideHistoryRemoteDataSource {
  final Dio _dio;

  PassengerRideHistoryRemoteDataSourceImpl(this._dio);

  @override
  Future<OffsetPage<Map<String, dynamic>>> fetchRideHistory(
    String passengerId, {
    int limit = 25,
    int offset = 0,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/passengers/${Uri.encodeComponent(passengerId)}/rides',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    return OffsetPage<Map<String, dynamic>>.fromJson(
      response.data ?? const <String, dynamic>{},
      (value) =>
          decodeObjectMap(value, message: 'Passenger ride item is invalid.'),
    );
  }

  @override
  Future<Map<String, dynamic>> fetchSummary(String passengerId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/passengers/${Uri.encodeComponent(passengerId)}/activity-summary',
    );
    return response.data ?? const <String, dynamic>{};
  }
}
