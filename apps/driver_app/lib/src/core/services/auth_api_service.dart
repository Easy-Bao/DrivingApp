import 'dart:convert';
import 'package:http/http.dart' as http;
import 'base_api_client.dart';

class AuthApiService extends BaseApiClient {
  AuthApiService({required super.baseUrl});

  Future<Map<String, dynamic>?> authenticateDriver({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        baseUrl.replace(path: '/drivers/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      return parseMapResponse(response, 200);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchProfile(String driverId) async {
    try {
      final response = await http.get(
        baseUrl.replace(path: '/drivers/$driverId'),
        headers: {'Content-Type': 'application/json'},
      );
      return parseMapResponse(response, 200);
    } catch (_) {
      return null;
    }
  }
}
