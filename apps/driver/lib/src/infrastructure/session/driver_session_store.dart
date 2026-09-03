import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:driver/src/infrastructure/session/driver_storage_keys.dart';

class DriverSessionStore({FlutterSecureStorage? storage}) {
  static const _defaultStorage = FlutterSecureStorage(
    // Keep the Android storage mode explicit for existing encrypted entries.
    // ignore: deprecated_member_use
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  final FlutterSecureStorage _storage;

  this : _storage = storage ?? _defaultStorage;

  Future<void> saveToken(String token) async {
    await _storage.write(key: DriverStorageKeys.jwtToken, value: token);
  }

  Future<String?> readToken() async {
    return _storage.read(key: DriverStorageKeys.jwtToken);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: DriverStorageKeys.refreshToken, value: token);
  }

  Future<String?> readRefreshToken() async {
    return _storage.read(key: DriverStorageKeys.refreshToken);
  }

  Future<void> saveDriverId(String driverId) async {
    await _storage.write(key: DriverStorageKeys.driverId, value: driverId);
  }

  Future<String?> readDriverId() async {
    return _storage.read(key: DriverStorageKeys.driverId);
  }

  Future<bool> hasValidDriverSession() async {
    final token = await readToken();
    final driverId = await readDriverId();
    return token?.trim().isNotEmpty == true &&
        driverId?.trim().isNotEmpty == true;
  }

  Future<void> saveDriverOnlineStatus(bool isOnline) async {
    await _storage.write(
      key: DriverStorageKeys.driverOnlineStatus,
      value: isOnline.toString(),
    );
  }

  Future<bool?> readDriverOnlineStatus() async {
    final value = await _storage.read(
      key: DriverStorageKeys.driverOnlineStatus,
    );
    return switch (value?.toLowerCase()) {
      'true' => true,
      'false' => false,
      _ => null,
    };
  }

  Future<void> savePassengerId(String passengerId) async {
    await _storage.write(
      key: DriverStorageKeys.passengerId,
      value: passengerId,
    );
  }

  Future<String?> readPassengerId() async {
    return _storage.read(key: DriverStorageKeys.passengerId);
  }

  Future<void> saveActiveRideId(String rideId) async {
    await _storage.write(key: DriverStorageKeys.activeRideId, value: rideId);
  }

  Future<String?> readActiveRideId() async {
    return _storage.read(key: DriverStorageKeys.activeRideId);
  }

  Future<void> clearSession() async {
    await Future.wait(
      const [
        DriverStorageKeys.jwtToken,
        DriverStorageKeys.refreshToken,
        DriverStorageKeys.driverId,
        DriverStorageKeys.driverOnlineStatus,
        DriverStorageKeys.passengerId,
        DriverStorageKeys.activeRideId,
      ].map((key) => _storage.delete(key: key)),
    );
  }
}
