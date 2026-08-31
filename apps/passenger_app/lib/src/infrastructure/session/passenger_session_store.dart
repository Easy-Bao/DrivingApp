import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:passenger_app/src/infrastructure/session/passenger_storage_keys.dart';

class PassengerSessionStore {
  final FlutterSecureStorage _storage;

  PassengerSessionStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await _storage.write(key: PassengerStorageKeys.jwtToken, value: token);
  }

  Future<String?> readToken() async {
    return _storage.read(key: PassengerStorageKeys.jwtToken);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: PassengerStorageKeys.jwtToken);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: PassengerStorageKeys.refreshToken, value: token);
  }

  Future<String?> readRefreshToken() async {
    return _storage.read(key: PassengerStorageKeys.refreshToken);
  }

  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: PassengerStorageKeys.refreshToken);
  }

  Future<void> savePassengerId(String passengerId) async {
    await _storage.write(key: PassengerStorageKeys.passengerId, value: passengerId);
  }

  Future<String?> readPassengerId() async {
    return _storage.read(key: PassengerStorageKeys.passengerId);
  }

  Future<void> deletePassengerId() async {
    await _storage.delete(key: PassengerStorageKeys.passengerId);
  }

  Future<void> saveActiveRideId(String rideId) async {
    await _storage.write(key: PassengerStorageKeys.activeRideId, value: rideId);
  }

  Future<String?> readActiveRideId() async {
    return _storage.read(key: PassengerStorageKeys.activeRideId);
  }

  Future<void> deleteActiveRideId() async {
    await _storage.delete(key: PassengerStorageKeys.activeRideId);
  }

  Future<void> clearSession() async {
    await _storage.deleteAll();
  }
}
