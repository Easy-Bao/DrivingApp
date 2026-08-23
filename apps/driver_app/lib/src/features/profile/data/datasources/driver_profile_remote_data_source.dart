import 'package:dio/dio.dart';

abstract class DriverProfileRemoteDataSource {
  Future<Map<String, dynamic>> fetchProfile(String driverId);
}

class DriverProfileRemoteDataSourceImpl
    implements DriverProfileRemoteDataSource {
  final Dio _dio;

  DriverProfileRemoteDataSourceImpl(this._dio);

  @override
  Future<Map<String, dynamic>> fetchProfile(String driverId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/drivers/${Uri.encodeComponent(driverId)}',
    );
    return response.data ?? const <String, dynamic>{};
  }
}
