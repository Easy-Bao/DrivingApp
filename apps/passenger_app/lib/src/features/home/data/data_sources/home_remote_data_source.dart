import 'package:dio/dio.dart';

abstract class HomeRemoteDataSource {
  Future<Map<String, dynamic>> fetchHomeData({
    required double lat,
    required double lng,
  });
}

class HomeRemoteDataSourceImpl(this._dio) implements HomeRemoteDataSource {
  final Dio _dio;

  @override
  Future<Map<String, dynamic>> fetchHomeData({
    required double lat,
    required double lng,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/passenger/home',
      queryParameters: {'lat': lat, 'lng': lng},
    );
    return response.data ?? {};
  }
}
