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

  static String _extractErrorMessage(dynamic responseData, String? statusMessage) {
    if (responseData is Map) {
      if (responseData.containsKey('issues') &&
          responseData['issues'] is List &&
          (responseData['issues'] as List).isNotEmpty) {
        final firstIssue = (responseData['issues'] as List).first;
        if (firstIssue is Map && firstIssue.containsKey('message')) {
          return firstIssue['message'].toString();
        }
      }
      return responseData['message']?.toString() ??
          responseData['error']?.toString() ??
          responseData.toString();
    } else if (responseData != null) {
      return responseData.toString();
    } else if (statusMessage != null) {
      return statusMessage;
    }
    return 'Server error';
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

    final extractedMessage = _extractErrorMessage(response.data, response.statusMessage);

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

    final extractedMessage = _extractErrorMessage(response.data, response.statusMessage);

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

    final extractedMessage = _extractErrorMessage(response.data, response.statusMessage);

    throw ServerException(
      statusCode: response.statusCode ?? 500,
      message: extractedMessage,
    );
  }
}
