import 'package:dio/dio.dart';

abstract class EarningsRemoteDataSource {
  Future<Map<String, dynamic>> fetchEarningsSummary(String driverId);
}

class EarningsRemoteDataSourceImpl(this._dio)
    implements EarningsRemoteDataSource {
  final Dio _dio;

  @override
  Future<Map<String, dynamic>> fetchEarningsSummary(String driverId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/drivers/${Uri.encodeComponent(driverId)}/earnings',
    );
    return response.data ?? const <String, dynamic>{};
  }
}
