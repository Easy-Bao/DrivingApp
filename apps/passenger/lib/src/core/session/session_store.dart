import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:passenger/src/core/session/storage_keys.dart';

class SessionStore({FlutterSecureStorage? storage}) {
  static const _defaultStorage = FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  final Map<String, String> _temporaryValues = {};
  bool _persistent = true;
  static const _sessionKeys = [
    StorageKeys.accessToken,
    StorageKeys.refreshToken,
    StorageKeys.driverId,
    StorageKeys.passengerId,
    StorageKeys.activeRideId,
    StorageKeys.activeBidSessionId,
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
    await _writeValue(key: StorageKeys.accessToken, value: token);
  }

  Future<String?> readToken() async {
    return _readValue(key: StorageKeys.accessToken);
  }

  Future<void> deleteToken() async {
    await _deleteKeys(const [StorageKeys.accessToken]);
  }

  Future<void> saveRefreshToken(String token) async {
    await _writeValue(key: StorageKeys.refreshToken, value: token);
  }

  Future<String?> readRefreshToken() async {
    return _readValue(key: StorageKeys.refreshToken);
  }

  Future<void> deleteRefreshToken() async {
    await _deleteKeys(const [StorageKeys.refreshToken]);
  }

  Future<void> savePassengerId(String passengerId) async {
    await _writeValue(key: StorageKeys.passengerId, value: passengerId);
  }

  Future<String?> readPassengerId() async {
    return _readValue(key: StorageKeys.passengerId);
  }

  Future<void> deletePassengerId() async {
    await _deleteKeys(const [StorageKeys.passengerId]);
  }

  Future<void> saveActiveRideId(String rideId) async {
    await _writeValue(key: StorageKeys.activeRideId, value: rideId);
  }

  Future<String?> readActiveRideId() async {
    return _readValue(key: StorageKeys.activeRideId);
  }

  Future<void> deleteActiveRideId() async {
    await _deleteKeys(const [StorageKeys.activeRideId]);
  }

  Future<void> saveActiveBidSessionId(String sessionId) async {
    await _writeValue(key: StorageKeys.activeBidSessionId, value: sessionId);
  }

  Future<String?> readActiveBidSessionId() async {
    return _readValue(key: StorageKeys.activeBidSessionId);
  }

  Future<void> deleteActiveBidSessionId() async {
    await _deleteKeys(const [StorageKeys.activeBidSessionId]);
  }

  Future<void> saveChatReadAt(String rideId, DateTime readAt) async {
    final normalizedRideId = rideId.trim();
    if (normalizedRideId.isEmpty) return;
    await _writeValue(
      key: StorageKeys.chatReadAt(normalizedRideId),
      value: readAt.toUtc().toIso8601String(),
    );
  }

  Future<DateTime?> readChatReadAt(String rideId) async {
    final normalizedRideId = rideId.trim();
    if (normalizedRideId.isEmpty) return null;
    final rawValue = await _readValue(
      key: StorageKeys.chatReadAt(normalizedRideId),
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
