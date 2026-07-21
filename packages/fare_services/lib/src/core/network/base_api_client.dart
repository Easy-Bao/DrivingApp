import 'dart:convert';
import 'package:dio/dio.dart';

abstract class BaseApiClient {
  final Uri baseUrl;
  final Dio _dio;

  BaseApiClient({required this.baseUrl, Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl.toString(),
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                headers: {'Content-Type': 'application/json'},
              ),
            );

  Dio get clientDio => _dio;

  Map<String, dynamic> parseMapResponse(Response response, int expectedStatusCode) {
    if (response.statusCode == expectedStatusCode && response.data != null) {
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      } else if (response.data is String) {
        return jsonDecode(response.data as String) as Map<String, dynamic>;
      }
    }
    return <String, dynamic>{};
  }

  List<dynamic> parseListResponse(Response response, int expectedStatusCode) {
    if (response.statusCode == expectedStatusCode && response.data != null) {
      if (response.data is List<dynamic>) {
        return response.data as List<dynamic>;
      } else if (response.data is String) {
        return jsonDecode(response.data as String) as List<dynamic>;
      }
    }
    return <dynamic>[];
  }
}
