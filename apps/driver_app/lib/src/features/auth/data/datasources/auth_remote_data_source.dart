import 'package:dio/dio.dart';
import 'package:driver_services/driver_services.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> authenticateDriver({
    required String email,
    required String password,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final AuthApiService _authApiService;

  AuthRemoteDataSourceImpl(this._authApiService);

  @override
  Future<Map<String, dynamic>> authenticateDriver({
    required String email,
    required String password,
  }) async {
    final result = await _authApiService.authenticateDriver(
      email: email,
      password: password,
    );
    if (result == null || result['driver'] == null) {
      throw DioException(
        requestOptions: RequestOptions(path: '/drivers/login'),
        error: 'Invalid email or password',
        type: DioExceptionType.badResponse,
      );
    }
    return result;
  }
}
