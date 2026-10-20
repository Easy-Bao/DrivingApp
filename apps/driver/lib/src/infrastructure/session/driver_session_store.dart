import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:driver/src/infrastructure/session/driver_storage_keys.dart';

class SessionStore({FlutterSecureStorage? storage}) {
  static const _defaultStorage = FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  this : _storage = storage ?? _defaultStorage;

  Future<void> saveToken(String token) async {
    await _storage.write(key: StorageKeys.accessToken, value: token);
  }

  Future<String?> readToken() async {
    return _storage.read(key: StorageKeys.accessToken);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: StorageKeys.refreshToken, value: token);
  }

  Future<String?> readRefreshToken() async {
    return _storage.read(key: StorageKeys.refreshToken);
  }

  Future<void> saveDriverId(String driverId) async {
    await _storage.write(key: StorageKeys.driverId, value: driverId);
  }

  Future<String?> readDriverId() async {
    return _storage.read(key: StorageKeys.driverId);
  }

  Future<bool> hasValidSession() async {
    final token = await readToken();
    final driverId = await readDriverId();
    return token?.trim().isNotEmpty == true &&
        driverId?.trim().isNotEmpty == true;
  }

  Future<void> saveDriverOnlineStatus(bool isOnline) async {
    await _storage.write(
      key: StorageKeys.driverOnlineStatus,
      value: isOnline.toString(),
    );
  }

  Future<bool?> readDriverOnlineStatus() async {
    final value = await _storage.read(key: StorageKeys.driverOnlineStatus);
    return switch (value?.toLowerCase()) {
      'true' => true,
      'false' => false,
      _ => null,
    };
  }

  Future<void> savePassengerId(String passengerId) async {
    await _storage.write(key: StorageKeys.passengerId, value: passengerId);
  }

  Future<String?> readPassengerId() async {
    return _storage.read(key: StorageKeys.passengerId);
  }

  Future<void> saveActiveRideId(String rideId) async {
    await _storage.write(key: StorageKeys.activeRideId, value: rideId);
  }

  Future<String?> readActiveRideId() async {
    return _storage.read(key: StorageKeys.activeRideId);
  }

  Future<void> clearActiveRideId() async {
    await _storage.delete(key: StorageKeys.activeRideId);
  }

  Future<void> clearSession() async {
    await Future.wait(
      const [
        StorageKeys.accessToken,
        StorageKeys.refreshToken,
        StorageKeys.driverId,
        StorageKeys.driverOnlineStatus,
        StorageKeys.driverOnlineSince,
        StorageKeys.passengerId,
        StorageKeys.activeRideId,
      ].map((key) => _storage.delete(key: key)),
    );
  }
}
