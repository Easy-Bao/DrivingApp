import 'package:dio/dio.dart';

abstract class PublicDriverRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchSummaries();
}

class PublicDriverRemoteDataSourceImpl implements PublicDriverRemoteDataSource {
  final Dio _dio;

  PublicDriverRemoteDataSourceImpl(this._dio);

  @override
  Future<List<Map<String, dynamic>>> fetchSummaries() async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/drivers/public/summaries',
      queryParameters: {'limit': 5},
    );
    return [
      for (final item in response.data ?? const <dynamic>[])
        if (item is Map) Map<String, dynamic>.from(item),
    ];
  }
}
