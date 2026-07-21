import 'package:driver_services/src/core/network/base_api_client.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> authenticateDriver({
    required String email,
    required String password,
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
      '/drivers/login',
      data: {'email': email, 'password': password},
    );
    return parseMapResponse(response, 200);
  }

  @override
  Future<Map<String, dynamic>> fetchProfile(String driverId) async {
    final response = await clientDio.get('/drivers/$driverId');
    return parseMapResponse(response, 200);
  }
}
