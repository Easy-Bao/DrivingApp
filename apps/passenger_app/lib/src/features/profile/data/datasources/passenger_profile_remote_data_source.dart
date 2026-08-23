import 'package:dio/dio.dart';

abstract class PassengerProfileRemoteDataSource {
  Future<Map<String, dynamic>> fetchProfile(String passengerId);

  Future<Map<String, dynamic>> updateProfile({
    required String passengerId,
    required Map<String, dynamic> data,
  });
}

class PassengerProfileRemoteDataSourceImpl
    implements PassengerProfileRemoteDataSource {
  final Dio _dio;

  PassengerProfileRemoteDataSourceImpl(this._dio);

  @override
  Future<Map<String, dynamic>> fetchProfile(String passengerId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/passengers/${Uri.encodeComponent(passengerId)}',
    );
    return response.data ?? const <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> updateProfile({
    required String passengerId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/v1/passengers/${Uri.encodeComponent(passengerId)}',
      data: data,
    );
    return response.data ?? const <String, dynamic>{};
  }
}
