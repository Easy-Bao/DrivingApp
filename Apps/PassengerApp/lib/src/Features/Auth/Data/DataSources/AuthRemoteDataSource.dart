import 'package:dio/dio.dart';

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

  Future<bool> verifyOtp({
    required String email,
    required String code,
  });

  Future<bool> resetPassword({
    required String email,
  });

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
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/passenger/signin',
      data: {'email': email, 'password': password},
    );
    return response.data ?? {};
  }

  @override
  Future<Map<String, dynamic>> registerPassenger({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/passenger/signup',
      data: {'name': name, 'email': email, 'phone': phone, 'password': password},
    );
    return response.data ?? {};
  }

  @override
  Future<bool> verifyOtp({required String email, required String code}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/passenger/verify-otp',
      data: {'email': email, 'code': code},
    );
    return response.statusCode == 200;
  }

  @override
  Future<bool> resetPassword({required String email}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/passenger/forgot-password',
      data: {'email': email},
    );
    return response.statusCode == 200;
  }

  @override
  Future<bool> confirmResetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/passenger/reset-password',
      data: {'email': email, 'code': code, 'new_password': newPassword},
    );
    return response.statusCode == 200;
  }
}
