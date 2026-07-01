/// Driver API Service: manages server communication for driver authentication, online status updates, and ride acceptance.
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:driver_app/core/config/env_config.dart';

class DriverApiService {
  DriverApiService._();

  static final String _baseUrl = EnvConfig.driverServiceUrl;

  /**
   * Authenticates a driver via POST /drivers/login.
   * Returns the raw JSON response containing driver profile and token, or null on failure.
   */
  static Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/drivers/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /**
   * Toggles online/offline status for a driver via POST /drivers/:id/online.
   * Returns true if status was successfully updated on the server.
   */
  static Future<bool> toggleOnline({
    required String driverId,
    required bool isOnline,
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/drivers/$driverId/online'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'isOnline': isOnline,
          'lat': lat,
          'lng': lng,
        }),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
