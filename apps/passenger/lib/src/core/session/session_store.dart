import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:passenger/src/core/session/storage_keys.dart';

class PassengerSessionStore({FlutterSecureStorage? storage}) {
  static const _defaultStorage = FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  final Map<String, String> _temporaryValues = {};
  bool _persistent = true;
  static const _sessionKeys = [
    PassengerStorageKeys.accessToken,
    PassengerStorageKeys.refreshToken,
    PassengerStorageKeys.driverId,
    PassengerStorageKeys.passengerId,
    PassengerStorageKeys.activeRideId,
    PassengerStorageKeys.activeBidSessionId,
  ];

  this : _storage = storage ?? _defaultStorage;

  Future<void> configurePersistence({required bool rememberMe}) async {
    if (!rememberMe) {
      await _deleteKeys(_sessionKeys);
    }
    _temporaryValues.clear();
    _persistent = rememberMe;
  }

  Future<void> _writeValue({required String key, required String value}) async {
    if (_persistent) {
      await _storage.write(key: key, value: value);
    } else {
      _temporaryValues[key] = value;
    }
  }

  Future<String?> _readValue({required String key}) async {
    if (_persistent) return _storage.read(key: key);
    return _temporaryValues[key];
  }

  Future<void> saveToken(String token) async {
    await _writeValue(key: PassengerStorageKeys.accessToken, value: token);
  }

  Future<String?> readToken() async {
    return _readValue(key: PassengerStorageKeys.accessToken);
  }

  Future<void> deleteToken() async {
    await _deleteKeys(const [PassengerStorageKeys.accessToken]);
  }

  Future<void> saveRefreshToken(String token) async {
    await _writeValue(key: PassengerStorageKeys.refreshToken, value: token);
  }

  Future<String?> readRefreshToken() async {
    return _readValue(key: PassengerStorageKeys.refreshToken);
  }

  Future<void> deleteRefreshToken() async {
    await _deleteKeys(const [PassengerStorageKeys.refreshToken]);
  }

  Future<void> savePassengerId(String passengerId) async {
    await _writeValue(
      key: PassengerStorageKeys.passengerId,
      value: passengerId,
    );
  }

  Future<String?> readPassengerId() async {
    return _readValue(key: PassengerStorageKeys.passengerId);
  }

  Future<void> deletePassengerId() async {
    await _deleteKeys(const [PassengerStorageKeys.passengerId]);
  }

  Future<void> saveActiveRideId(String rideId) async {
    await _writeValue(key: PassengerStorageKeys.activeRideId, value: rideId);
  }

  Future<String?> readActiveRideId() async {
    return _readValue(key: PassengerStorageKeys.activeRideId);
  }

  Future<void> deleteActiveRideId() async {
    await _deleteKeys(const [PassengerStorageKeys.activeRideId]);
  }

  Future<void> saveActiveBidSessionId(String sessionId) async {
    await _writeValue(
      key: PassengerStorageKeys.activeBidSessionId,
      value: sessionId,
    );
  }

  Future<String?> readActiveBidSessionId() async {
    return _readValue(key: PassengerStorageKeys.activeBidSessionId);
  }

  Future<void> deleteActiveBidSessionId() async {
    await _deleteKeys(const [PassengerStorageKeys.activeBidSessionId]);
  }

  Future<void> saveChatReadAt(String rideId, DateTime readAt) async {
    final normalizedRideId = rideId.trim();
    if (normalizedRideId.isEmpty) return;
    await _writeValue(
      key: PassengerStorageKeys.chatReadAt(normalizedRideId),
      value: readAt.toUtc().toIso8601String(),
    );
  }

  Future<DateTime?> readChatReadAt(String rideId) async {
    final normalizedRideId = rideId.trim();
    if (normalizedRideId.isEmpty) return null;
    final rawValue = await _readValue(
      key: PassengerStorageKeys.chatReadAt(normalizedRideId),
    );
    if (rawValue == null || rawValue.trim().isEmpty) return null;
    return DateTime.tryParse(rawValue)?.toUtc();
  }

  Future<void> clearAll() async {
    await _deleteKeys(_sessionKeys);
    _temporaryValues.clear();
    _persistent = true;
  }

  Future<void> clearSession() => clearAll();

  Future<void> _deleteKeys(Iterable<String> keys) async {
    for (final key in keys) {
      _temporaryValues.remove(key);
    }
    await Future.wait(keys.map((key) => _storage.delete(key: key)));
  }
}
