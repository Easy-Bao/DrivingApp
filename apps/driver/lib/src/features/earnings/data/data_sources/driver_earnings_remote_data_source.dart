import 'package:dio/dio.dart';

abstract class DriverEarningsRemoteDataSource {
  Future<Map<String, dynamic>> fetchEarningsSummary(String driverId);
}

class DriverEarningsRemoteDataSourceImpl(this._dio)
    implements DriverEarningsRemoteDataSource {
  final Dio _dio;

  @override
  Future<Map<String, dynamic>> fetchEarningsSummary(String driverId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/drivers/${Uri.encodeComponent(driverId)}/earnings',
    );
    return response.data ?? const <String, dynamic>{};
  }
}
