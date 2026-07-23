import 'package:driver_services/src/core/network/base_api_client.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> authenticateDriver({
    required String email,
    required String password,
  });

  Future<Map<String, dynamic>> registerDriver({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String vehicleType,
    required String plateNumber,
  });

  Future<bool> verifyOtp({
    required String email,
    required String code,
  });

  Future<bool> forgotPassword({
    required String email,
  });

  Future<Map<String, dynamic>> fetchProfile(String driverId);
}

class AuthRemoteDataSourceImpl extends BaseApiClient implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({required super.baseUrl, super.dio});

  @override
  Future<Map<String, dynamic>> authenticateDriver({
    required String email,
    required String password,
  }) async {
    final response = await clientDio.post(
      '/auth/driver/login',
      data: {'email': email, 'password': password},
    );
    final parsed = parseMapResponse(response, 200);
    if (parsed.containsKey('data') && parsed['data'] is Map<String, dynamic>) {
      final dataMap = Map<String, dynamic>.from(parsed['data'] as Map<String, dynamic>);
      if (dataMap.containsKey('user') && !dataMap.containsKey('driver')) {
        dataMap['driver'] = dataMap['user'];
      }
      return dataMap;
    }
    return parsed;
  }

  @override
  Future<Map<String, dynamic>> registerDriver({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String vehicleType,
    required String plateNumber,
  }) async {
    final response = await clientDio.post(
      '/auth/driver/register',
      data: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'vehicleType': vehicleType,
        'plateNumber': plateNumber,
      },
    );
    final parsed = parseMapResponse(response, 200);
    if (parsed.containsKey('data') && parsed['data'] is Map<String, dynamic>) {
      final dataMap = Map<String, dynamic>.from(parsed['data'] as Map<String, dynamic>);
      if (dataMap.containsKey('user') && !dataMap.containsKey('driver')) {
        dataMap['driver'] = dataMap['user'];
      }
      return dataMap;
    }
    return parsed;
  }

  @override
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

  @override
  Future<bool> forgotPassword({
    required String email,
  }) async {
    final response = await clientDio.post(
      '/auth/forgot-password',
      data: {'email': email},
    );
    return response.statusCode == 200;
  }

  @override
  Future<Map<String, dynamic>> fetchProfile(String driverId) async {
    final response = await clientDio.get('/drivers/$driverId');
    return parseMapResponse(response, 200);
  }
}
