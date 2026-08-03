import 'package:dio/dio.dart';

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
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/driver/login',
      data: {'email': email, 'password': password},
    );
    return response.data ?? {};
  }

  @override
  Future<void> resetPassword({required String email}) async {
    await _dio.post<void>(
      '/auth/driver/forgot-password',
      data: {'email': email},
    );
  }
}
