import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure persistence storage interface for driver credentials and session tokens.
class SecureSessionService {
  final FlutterSecureStorage _storage;

  SecureSessionService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  Future<void> writeAuthToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  Future<String?> readAuthToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<void> writeDriverId(String driverId) async {
    await _storage.write(key: 'driver_id', value: driverId);
  }

  Future<String?> readDriverId() async {
    return await _storage.read(key: 'driver_id');
  }

  Future<void> clearSession() async {
    await _storage.deleteAll();
  }
}
