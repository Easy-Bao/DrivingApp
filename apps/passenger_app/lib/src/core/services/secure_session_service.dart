import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure persistence storage interface for passenger credentials and session tokens.
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

  Future<void> writePassengerId(String passengerId) async {
    await _storage.write(key: 'passenger_id', value: passengerId);
  }

  Future<String?> readPassengerId() async {
    return await _storage.read(key: 'passenger_id');
  }

  Future<void> writeActiveRideId(String activeRideId) async {
    await _storage.write(key: 'active_ride_id', value: activeRideId);
  }

  Future<String?> readActiveRideId() async {
    return await _storage.read(key: 'active_ride_id');
  }

  Future<void> deleteActiveRideId() async {
    await _storage.delete(key: 'active_ride_id');
  }

  Future<void> clearSession() async {
    await _storage.deleteAll();
  }
}
