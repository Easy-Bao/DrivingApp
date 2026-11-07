import 'package:dio/dio.dart';

abstract class PerformanceRemoteDataSource {
  Future<Map<String, dynamic>> fetchStats(String driverId);
}

class PerformanceRemoteDataSourceImpl(this._dio)
    implements PerformanceRemoteDataSource {
  final Dio _dio;

  @override
  Future<Map<String, dynamic>> fetchStats(String driverId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/drivers/${Uri.encodeComponent(driverId)}/stats',
    );
    return response.data ?? const <String, dynamic>{};
  }
}
