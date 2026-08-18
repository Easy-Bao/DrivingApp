import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:driver_app/src/core/constants/storage_keys.dart';

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

  Future<void> saveDriverId(String driverId) async {
    await _storage.write(key: StorageKeys.driverId, value: driverId);
  }

  Future<String?> readDriverId() async {
    return _storage.read(key: StorageKeys.driverId);
  }

  Future<bool> hasValidDriverSession() async {
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

  Future<void> clearSession() async {
    await _storage.deleteAll();
  }
}
