import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:passenger/src/infrastructure/session/passenger_storage_keys.dart';

class PassengerSessionStore({FlutterSecureStorage? storage}) {
  static const _defaultStorage = FlutterSecureStorage(
    // Keep the Android storage mode explicit for existing encrypted entries.
    // ignore: deprecated_member_use
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  final FlutterSecureStorage _storage;

  this : _storage = storage ?? _defaultStorage;

  Future<void> saveToken(String token) async {
    await _storage.write(key: PassengerStorageKeys.jwtToken, value: token);
  }

  Future<String?> readToken() async {
    return _storage.read(key: PassengerStorageKeys.jwtToken);
  }

  Future<void> deleteToken() async {
    await _deleteKeys(const [PassengerStorageKeys.jwtToken]);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: PassengerStorageKeys.refreshToken, value: token);
  }

  Future<String?> readRefreshToken() async {
    return _storage.read(key: PassengerStorageKeys.refreshToken);
  }

  Future<void> deleteRefreshToken() async {
    await _deleteKeys(const [PassengerStorageKeys.refreshToken]);
  }

  Future<void> savePassengerId(String passengerId) async {
    await _storage.write(
      key: PassengerStorageKeys.passengerId,
      value: passengerId,
    );
  }

  Future<String?> readPassengerId() async {
    return _storage.read(key: PassengerStorageKeys.passengerId);
  }

  Future<void> deletePassengerId() async {
    await _deleteKeys(const [PassengerStorageKeys.passengerId]);
  }

  Future<void> saveActiveRideId(String rideId) async {
    await _storage.write(key: PassengerStorageKeys.activeRideId, value: rideId);
  }

  Future<String?> readActiveRideId() async {
    return _storage.read(key: PassengerStorageKeys.activeRideId);
  }

  Future<void> deleteActiveRideId() async {
    await _deleteKeys(const [PassengerStorageKeys.activeRideId]);
  }

  Future<void> saveActiveBidSessionId(String sessionId) async {
    await _storage.write(
      key: PassengerStorageKeys.activeBidSessionId,
      value: sessionId,
    );
  }

  Future<String?> readActiveBidSessionId() async {
    return _storage.read(key: PassengerStorageKeys.activeBidSessionId);
  }

  Future<void> deleteActiveBidSessionId() async {
    await _deleteKeys(const [PassengerStorageKeys.activeBidSessionId]);
  }

  Future<void> saveChatReadAt(String rideId, DateTime readAt) async {
    final normalizedRideId = rideId.trim();
    if (normalizedRideId.isEmpty) return;
    await _storage.write(
      key: PassengerStorageKeys.chatReadAt(normalizedRideId),
      value: readAt.toUtc().toIso8601String(),
    );
  }

  Future<DateTime?> readChatReadAt(String rideId) async {
    final normalizedRideId = rideId.trim();
    if (normalizedRideId.isEmpty) return null;
    final rawValue = await _storage.read(
      key: PassengerStorageKeys.chatReadAt(normalizedRideId),
    );
    if (rawValue == null || rawValue.trim().isEmpty) return null;
    return DateTime.tryParse(rawValue)?.toUtc();
  }

  Future<void> clearAll() async {
    await _deleteKeys(const [
      PassengerStorageKeys.jwtToken,
      PassengerStorageKeys.refreshToken,
      PassengerStorageKeys.driverId,
      PassengerStorageKeys.passengerId,
      PassengerStorageKeys.activeRideId,
      PassengerStorageKeys.activeBidSessionId,
    ]);
  }

  Future<void> clearSession() => clearAll();

  Future<void> _deleteKeys(Iterable<String> keys) async {
    await Future.wait(keys.map((key) => _storage.delete(key: key)));
  }
}
