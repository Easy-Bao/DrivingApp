import 'package:dio/dio.dart';
import 'package:passenger_app/src/core/constants/api_endpoints.dart';
import 'package:shared_core/shared_core.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> loginPassenger({
    required String email,
    required String password,
  });

  Future<Map<String, dynamic>> registerPassenger({
    required String name,
    required String email,
    required String phone,
    required String password,
  });

  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String code,
  });

  Future<bool> requestVerificationCode({required String email});

  Future<bool> resetPassword({required String email});

  Future<bool> confirmResetPassword({
    required String email,
    required String code,
    required String newPassword,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSourceImpl(this._dio);

  @override
  Future<Map<String, dynamic>> loginPassenger({
    required String email,
    required String password,
  }) async {
    final responseBody = await _postJson(
      ApiEndpoints.passengerLogin,
      requestBody: {'email': email, 'password': password},
    );
    return _extractDataPayload(responseBody);
  }

  @override
  Future<Map<String, dynamic>> registerPassenger({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final responseBody = await _postJson(
      ApiEndpoints.passengerRegister,
      requestBody: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
      },
    );
    return _extractDataPayload(responseBody);
  }

  @override
  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String code,
  }) async {
    final responseBody = await _postJson(
      ApiEndpoints.verifyOtp,
      requestBody: {'email': email, 'code': code},
    );
    return _extractDataPayload(responseBody);
  }

  @override
  Future<bool> requestVerificationCode({required String email}) async {
    final responseBody = await _postJson(
      ApiEndpoints.passengerOtp,
      requestBody: {'email': email},
    );
    return responseBody['success'] == true;
  }

  @override
  Future<bool> resetPassword({required String email}) async {
    final responseBody = await _postJson(
      ApiEndpoints.forgotPassword,
      requestBody: {'email': email},
    );
    return responseBody['success'] == true;
  }

  @override
  Future<bool> confirmResetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final responseBody = await _postJson(
      ApiEndpoints.resetPassword,
      requestBody: {'email': email, 'code': code, 'newPassword': newPassword},
    );
    return responseBody['success'] == true;
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
