import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureSessionService {
  final FlutterSecureStorage _storage;

  static const String _keyToken = 'jwt_token';
  static const String _keyPassengerId = 'passenger_id';
  static const String _keyActiveRideId = 'active_ride_id';

  SecureSessionService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  Future<String?> readToken() async {
    return await _storage.read(key: _keyToken);
  }

  Future<void> savePassengerId(String passengerId) async {
    await _storage.write(key: _keyPassengerId, value: passengerId);
  }

  Future<String?> readPassengerId() async {
    return await _storage.read(key: _keyPassengerId);
  }

  Future<void> saveActiveRideId(String rideId) async {
    await _storage.write(key: _keyActiveRideId, value: rideId);
  }

  Future<String?> readActiveRideId() async {
    return await _storage.read(key: _keyActiveRideId);
  }

  Future<void> clearSession() async {
    await _storage.deleteAll();
  }
}
