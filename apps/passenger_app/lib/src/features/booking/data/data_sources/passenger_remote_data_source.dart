import 'package:dio/dio.dart';

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
    final response = await _dio.get<Map<String, dynamic>>('/passengers/$passengerId');
    return response.data ?? {};
  }

  @override
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final passengerId = data['id'] as String? ?? '';
    final response = await _dio.patch<Map<String, dynamic>>(
      '/passengers/$passengerId',
      data: data,
    );
    return response.data ?? {};
  }

  @override
  Future<List<dynamic>> fetchRideHistory(String passengerId) async {
    final response = await _dio.get<List<dynamic>>('/passengers/$passengerId/trips');
    return response.data ?? [];
  }

  @override
  Future<List<dynamic>> fetchNotifications(String passengerId) async {
    final response = await _dio.get<List<dynamic>>('/passengers/$passengerId/notifications');
    return response.data ?? [];
  }
}
