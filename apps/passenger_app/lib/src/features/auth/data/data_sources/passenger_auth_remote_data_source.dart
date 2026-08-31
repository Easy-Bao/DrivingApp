import 'package:dio/dio.dart';
import 'package:foundation/foundation.dart';

abstract interface class PassengerAuthRemoteDataSource {
  Future<Map<String, dynamic>> postJson(
    String path, {
    required Map<String, dynamic> requestBody,
  });

  Future<Map<String, dynamic>> postData(
    String path, {
    required Map<String, dynamic> requestBody,
  });
}

final class PassengerAuthRemoteDataSourceImpl
    implements PassengerAuthRemoteDataSource {
  PassengerAuthRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<Map<String, dynamic>> postJson(
    String path, {
    required Map<String, dynamic> requestBody,
  }) async {
    try {
      final response = await _dio.post<Object?>(path, data: requestBody);
      final responseData = response.data;
      if (responseData is! Map) {
        throw DataParsingException(
          message: 'Authentication service returned an invalid response.',
        );
      }
      return Map<String, dynamic>.from(responseData);
    } on DioException catch (error) {
      throw ServerException(
        statusCode: error.response?.statusCode ?? (_isTimeout(error) ? 504 : 0),
        message: _extractErrorMessage(error),
      );
    }
  }

  @override
  Future<Map<String, dynamic>> postData(
    String path, {
    required Map<String, dynamic> requestBody,
  }) async {
    final responseBody = await postJson(path, requestBody: requestBody);
    final responseData = responseBody['data'];
    if (responseBody['success'] != true || responseData is! Map) {
      throw DataParsingException(
        message: 'Authentication service returned an invalid response.',
      );
    }
    return Map<String, dynamic>.from(responseData);
  }

  String _extractErrorMessage(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode == null) {
      return 'Cannot reach the authentication service. Check that the local services are running.';
    }
    if (statusCode >= 500) {
      return 'The authentication service is temporarily unavailable. Please try again.';
    }
    return switch (statusCode) {
      400 ||
      422 => 'The request could not be completed. Please check your details.',
      401 || 403 => 'Invalid email or password.',
      404 => 'The requested authentication action is unavailable.',
      409 => 'This email is already registered.',
      _ => 'Authentication request failed. Please try again.',
    };
  }

  bool _isTimeout(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout;
  }
}
