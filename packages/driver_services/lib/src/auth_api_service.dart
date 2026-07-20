import 'package:driver_services/src/base_api_client.dart';

class AuthApiService extends BaseApiClient {
  AuthApiService({required super.baseUrl, super.dio});

  Future<Map<String, dynamic>?> authenticateDriver({
    required String email,
    required String password,
  }) async {
    try {
      final response = await clientDio.post(
        '/drivers/login',
        data: {'email': email, 'password': password},
      );
      return parseMapResponse(response, 200);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchProfile(String driverId) async {
    try {
      final response = await clientDio.get('/drivers/$driverId');
      return parseMapResponse(response, 200);
    } catch (_) {
      return null;
    }
  }
}
