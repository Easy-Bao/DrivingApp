import 'package:dio/dio.dart';

abstract class PublicDriverRemoteDataSource {
  Future<List<dynamic>> fetchSummaries();
}

class PublicDriverRemoteDataSourceImpl implements PublicDriverRemoteDataSource {
  final Dio _dio;

  PublicDriverRemoteDataSourceImpl(this._dio);

  @override
  Future<List<dynamic>> fetchSummaries() async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/drivers/public/summaries',
      queryParameters: {'limit': 5},
    );
    return response.data ?? const <dynamic>[];
  }
}
