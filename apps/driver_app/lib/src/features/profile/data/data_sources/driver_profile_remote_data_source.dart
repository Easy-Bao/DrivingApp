import 'package:dio/dio.dart';

abstract class DriverProfileRemoteDataSource {
  Future<Map<String, dynamic>> fetchProfile(String driverId);

  Future<Map<String, dynamic>> updateProfile({
    required Map<String, dynamic> data,
  });
}

class DriverProfileRemoteDataSourceImpl(this._dio)
    implements DriverProfileRemoteDataSource {
  final Dio _dio;

  @override
  Future<Map<String, dynamic>> fetchProfile(String driverId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/drivers/${Uri.encodeComponent(driverId)}',
    );
    return response.data ?? const <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> updateProfile({
    required Map<String, dynamic> data,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/api/v1/users/me',
      data: data,
    );
    return response.data ?? const <String, dynamic>{};
  }
}
