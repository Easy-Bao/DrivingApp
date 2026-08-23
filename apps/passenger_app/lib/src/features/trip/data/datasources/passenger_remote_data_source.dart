import 'package:dio/dio.dart';
import 'package:shared_core/shared_core.dart';

abstract class PassengerRemoteDataSource {
  Future<Map<String, dynamic>> fetchPassengerProfile(String passengerId);
  Future<Map<String, dynamic>> updateProfile({
    required String passengerId,
    required Map<String, dynamic> data,
  });
  Future<OffsetPage<Map<String, dynamic>>> fetchRideHistory(
    String passengerId, {
    int limit = 25,
    int offset = 0,
  });
  Future<Map<String, dynamic>> fetchActivitySummary(String passengerId);
  Future<OffsetPage<Map<String, dynamic>>> fetchNotifications(
    String passengerId, {
    int limit = 50,
    int offset = 0,
  });
}

class PassengerRemoteDataSourceImpl implements PassengerRemoteDataSource {
  final Dio _dio;

  PassengerRemoteDataSourceImpl(this._dio);

  @override
  Future<Map<String, dynamic>> fetchPassengerProfile(String passengerId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/passengers/$passengerId',
    );
    return response.data ?? {};
  }

  @override
  Future<Map<String, dynamic>> updateProfile({
    required String passengerId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/v1/passengers/$passengerId',
      data: data,
    );
    return response.data ?? {};
  }

  @override
  Future<OffsetPage<Map<String, dynamic>>> fetchRideHistory(
    String passengerId, {
    int limit = 25,
    int offset = 0,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/passengers/$passengerId/rides',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    return _decodePage(response.data);
  }

  @override
  Future<Map<String, dynamic>> fetchActivitySummary(String passengerId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/passengers/$passengerId/activity-summary',
    );
    return response.data ?? const <String, dynamic>{};
  }

  @override
  Future<OffsetPage<Map<String, dynamic>>> fetchNotifications(
    String passengerId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/passengers/$passengerId/notifications',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    return _decodePage(response.data);
  }

  OffsetPage<Map<String, dynamic>> _decodePage(Map<String, dynamic>? data) {
    return OffsetPage<Map<String, dynamic>>.fromJson(
      data ?? const <String, dynamic>{},
      (value) => Map<String, dynamic>.from(value! as Map),
    );
  }
}
