import 'package:dio/dio.dart';
import 'package:passenger_services/src/core/network/base_api_client.dart';

class AuthRemoteDataSource extends BaseApiClient {
  AuthRemoteDataSource({
    required super.baseUrl,
    super.dio,
  });

  Future<Map<String, dynamic>> loginPassenger({
    required String email,
    required String password,
  }) async {
    final response = await clientDio.post(
      '/passengers/login',
      data: {'email': email, 'password': password},
    );
    return parseMapResponse(response, 200);
  }

  Future<Map<String, dynamic>> registerPassenger({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await clientDio.post(
      '/passengers',
      data: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
      },
    );
    return parseMapResponse(response, 201);
  }

  Future<bool> verifyOtp({
    required String email,
    required String code,
  }) async {
    final response = await clientDio.post(
      '/passengers/verify-otp',
      data: {'email': email, 'code': code},
    );
    return parseBoolResponse(response, 200);
  }

  Future<bool> forgotPassword({
    required String email,
  }) async {
    final response = await clientDio.post(
      '/passengers/forgot-password',
      data: {'email': email},
    );
    return parseBoolResponse(response, 200);
  }
}
