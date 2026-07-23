import 'dart:convert';

import 'package:core_models/core_models.dart';
import 'package:dio/dio.dart';

abstract class BaseApiClient {
  final Uri baseUrl;
  final Dio clientDio;

  BaseApiClient({
    required this.baseUrl,
    Dio? dio,
  }) : clientDio = _createDioClient(baseUrl, dio);

  static Dio _createDioClient(Uri baseUrl, Dio? parentDio) {
    final newDio = Dio(
      BaseOptions(
        baseUrl: baseUrl.toString(),
        connectTimeout: parentDio?.options.connectTimeout ?? const Duration(seconds: 15),
        receiveTimeout: parentDio?.options.receiveTimeout ?? const Duration(seconds: 15),
        sendTimeout: parentDio?.options.sendTimeout ?? const Duration(seconds: 15),
        validateStatus: (status) => status != null,
      ),
    );
    if (parentDio != null) {
      newDio.interceptors.addAll(parentDio.interceptors);
    }
    return newDio;
  }

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

    String extractedMessage = 'Server error';
    if (response.data is Map) {
      final map = response.data as Map;
      extractedMessage = map['message']?.toString() ??
          map['error']?.toString() ??
          response.data.toString();
    } else if (response.data != null) {
      extractedMessage = response.data.toString();
    } else if (response.statusMessage != null) {
      extractedMessage = response.statusMessage!;
    }

    throw ServerException(
      statusCode: response.statusCode ?? 500,
      message: extractedMessage,
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

    String extractedMessage = 'Server error';
    if (response.data is Map) {
      final map = response.data as Map;
      extractedMessage = map['message']?.toString() ??
          map['error']?.toString() ??
          response.data.toString();
    } else if (response.data != null) {
      extractedMessage = response.data.toString();
    } else if (response.statusMessage != null) {
      extractedMessage = response.statusMessage!;
    }

    throw ServerException(
      statusCode: response.statusCode ?? 500,
      message: extractedMessage,
    );
  }

  bool parseBoolResponse(
    Response<dynamic> response,
    int expectedStatus,
  ) {
    if (response.statusCode == expectedStatus) {
      return true;
    }

    String extractedMessage = 'Server error';
    if (response.data is Map) {
      final map = response.data as Map;
      extractedMessage = map['message']?.toString() ??
          map['error']?.toString() ??
          response.data.toString();
    } else if (response.data != null) {
      extractedMessage = response.data.toString();
    } else if (response.statusMessage != null) {
      extractedMessage = response.statusMessage!;
    }

    throw ServerException(
      statusCode: response.statusCode ?? 500,
      message: extractedMessage,
    );
  }
}
