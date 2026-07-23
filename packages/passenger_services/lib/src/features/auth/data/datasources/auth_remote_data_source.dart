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
      '/auth/passenger/login',
      data: {'email': email, 'password': password},
    );
    final parsed = parseMapResponse(response, 200);
    if (parsed.containsKey('data') && parsed['data'] is Map<String, dynamic>) {
      final dataMap = Map<String, dynamic>.from(parsed['data'] as Map<String, dynamic>);
      if (dataMap.containsKey('user') && !dataMap.containsKey('passenger')) {
        dataMap['passenger'] = dataMap['user'];
      }
      return dataMap;
    }
    return parsed;
  }

  Future<Map<String, dynamic>> registerPassenger({
    required String name,
    required String email,
    required String phone,
    required String password,
    String preferredRideType = 'solo-ride',
  }) async {
    final response = await clientDio.post(
      '/auth/passenger/register',
      data: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'preferred_ride_type': preferredRideType,
      },
    );
    final parsed = parseMapResponse(response, 200);
    if (parsed.containsKey('data') && parsed['data'] is Map<String, dynamic>) {
      final dataMap = Map<String, dynamic>.from(parsed['data'] as Map<String, dynamic>);
      if (dataMap.containsKey('user') && !dataMap.containsKey('passenger')) {
        dataMap['passenger'] = dataMap['user'];
      }
      return dataMap;
    }
    return parsed;
  }

  Future<bool> verifyOtp({
    required String email,
    required String code,
  }) async {
    final response = await clientDio.post(
      '/auth/verify-otp',
      data: {'email': email, 'code': code},
    );
    return response.statusCode == 200;
  }

  Future<bool> forgotPassword({
    required String email,
  }) async {
    final response = await clientDio.post(
      '/auth/forgot-password',
      data: {'email': email},
    );
    return response.statusCode == 200;
  }
}
