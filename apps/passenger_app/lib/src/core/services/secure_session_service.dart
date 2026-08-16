import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:passenger_app/src/core/constants/storage_keys.dart';

class SecureSessionService {
  final FlutterSecureStorage _storage;

  SecureSessionService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await _storage.write(key: StorageKeys.jwtToken, value: token);
  }

  Future<String?> readToken() async {
    return _storage.read(key: StorageKeys.jwtToken);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: StorageKeys.jwtToken);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: StorageKeys.refreshToken, value: token);
  }

  Future<String?> readRefreshToken() async {
    return _storage.read(key: StorageKeys.refreshToken);
  }

  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: StorageKeys.refreshToken);
  }

  Future<void> savePassengerId(String passengerId) async {
    await _storage.write(key: StorageKeys.passengerId, value: passengerId);
  }

  Future<String?> readPassengerId() async {
    return _storage.read(key: StorageKeys.passengerId);
  }

  Future<void> deletePassengerId() async {
    await _storage.delete(key: StorageKeys.passengerId);
  }

  Future<void> saveActiveRideId(String rideId) async {
    await _storage.write(key: StorageKeys.activeRideId, value: rideId);
  }

  Future<String?> readActiveRideId() async {
    return _storage.read(key: StorageKeys.activeRideId);
  }

  Future<void> deleteActiveRideId() async {
    await _storage.delete(key: StorageKeys.activeRideId);
  }

  Future<void> clearSession() async {
    await _storage.deleteAll();
  }
}
