import 'package:dio/dio.dart';
import 'package:driver_app/src/core/constants/api_endpoints.dart';
import 'package:shared_core/shared_core.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> authenticateDriver({
    required String email,
    required String password,
  });

  Future<void> resetPassword({required String email});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSourceImpl(this._dio);

  @override
  Future<Map<String, dynamic>> authenticateDriver({
    required String email,
    required String password,
  }) async {
    final responseBody = await _postJson(
      ApiEndpoints.driverLogin,
      requestBody: {'email': email, 'password': password},
    );
    return _extractDataPayload(responseBody);
  }

  @override
  Future<void> resetPassword({required String email}) async {
    await _dio.post<void>(
      ApiEndpoints.driverForgotPassword,
      data: {'email': email},
    );
  }

  Future<Map<String, dynamic>> _postJson(
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

  Map<String, dynamic> _extractDataPayload(Map<String, dynamic> responseBody) {
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
      _ => 'Authentication request failed. Please try again.',
    };
  }

  bool _isTimeout(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout;
  }
}
