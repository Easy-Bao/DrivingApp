import 'package:dio/dio.dart';
import 'package:shared_core/shared_core.dart';

abstract class PassengerRemoteDataSource {
  Future<Map<String, dynamic>> fetchPassengerProfile(String passengerId);
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data);
  Future<List<dynamic>> fetchRideHistory(String passengerId);
  Future<List<dynamic>> fetchNotifications(String passengerId);
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
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final passengerId = SafeParse.toStringValue(data['id']);
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/v1/passengers/$passengerId',
      data: data,
    );
    return response.data ?? {};
  }

  @override
  Future<List<dynamic>> fetchRideHistory(String passengerId) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/passengers/$passengerId/rides',
    );
    return response.data ?? [];
  }

  @override
  Future<List<dynamic>> fetchNotifications(String passengerId) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/passengers/$passengerId/notifications',
    );
    return response.data ?? [];
  }
}
