import 'dart:convert';

import 'package:core_models/core_models.dart';
import 'package:dio/dio.dart';

abstract class BaseApiClient {
  final Uri baseUrl;
  final Dio clientDio;

  BaseApiClient({
    required this.baseUrl,
    Dio? dio,
  }) : clientDio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl.toString(),
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                validateStatus: (status) => status != null,
              ),
            );

  Map<String, dynamic> parseMapResponse(
    Response<dynamic> response,
    int expectedStatus,
  ) {
    if (response.statusCode == expectedStatus) {
      try {
        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        } else if (response.data is String) {
          return jsonDecode(response.data as String) as Map<String, dynamic>;
        }
      } catch (error) {
        throw DataParsingException(
          message: 'Failed to parse response payload: $error',
        );
      }
    }
    throw ServerException(
      statusCode: response.statusCode ?? 500,
      message: response.data?.toString() ?? response.statusMessage ?? 'Server error',
    );
  }

  List<dynamic> parseListResponse(
    Response<dynamic> response,
    int expectedStatus,
  ) {
    if (response.statusCode == expectedStatus) {
      try {
        if (response.data is List<dynamic>) {
          return response.data as List<dynamic>;
        } else if (response.data is String) {
          return jsonDecode(response.data as String) as List<dynamic>;
        }
      } catch (error) {
        throw DataParsingException(
          message: 'Failed to parse response list: $error',
        );
      }
    }
    throw ServerException(
      statusCode: response.statusCode ?? 500,
      message: response.data?.toString() ?? response.statusMessage ?? 'Server error',
    );
  }

  bool parseBoolResponse(
    Response<dynamic> response,
    int expectedStatus,
  ) {
    if (response.statusCode == expectedStatus) {
      return true;
    }
    throw ServerException(
      statusCode: response.statusCode ?? 500,
      message: response.data?.toString() ?? response.statusMessage ?? 'Server error',
    );
  }
}
