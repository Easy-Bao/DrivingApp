import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:passenger/src/core/session/storage_keys.dart';

typedef PendingBidSessionCreation = ({
  String idempotencyKey,
  String requestPayload,
  bool cancelRequested,
  String? sessionId,
});

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
    StorageKeys.pendingBidSessionCreation,
    StorageKeys.pendingBidSessionCancellationId,
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

  Future<void> savePendingBidSessionCreation({
    required String idempotencyKey,
    required String requestPayload,
    bool cancelRequested = false,
    String? sessionId,
  }) async {
    final payload = <String, Object?>{
      'idempotency_key': idempotencyKey,
      'request_payload': requestPayload,
      'cancel_requested': cancelRequested,
    };
    final normalizedSessionId = sessionId?.trim();
    if (normalizedSessionId != null && normalizedSessionId.isNotEmpty) {
      payload['session_id'] = normalizedSessionId;
    }
    await _writeValue(
      key: StorageKeys.pendingBidSessionCreation,
      value: jsonEncode(payload),
    );
  }

  Future<PendingBidSessionCreation?> readPendingBidSessionCreation() async {
    final stored = await _readValue(key: StorageKeys.pendingBidSessionCreation);
    if (stored == null || stored.trim().isEmpty) return null;

    final decoded = jsonDecode(stored);
    if (decoded is! Map) {
      throw const FormatException('Saved booking request is invalid.');
    }
    final idempotencyKey = decoded['idempotency_key'];
    final requestPayload = decoded['request_payload'];
    final sessionId = decoded['session_id'];
    if (idempotencyKey is! String ||
        idempotencyKey.trim().isEmpty ||
        requestPayload is! String ||
        requestPayload.trim().isEmpty) {
      throw const FormatException('Saved booking request is incomplete.');
    }
    final String? parsedSessionId;
    if (sessionId == null) {
      parsedSessionId = null;
    } else if (sessionId is String) {
      parsedSessionId = sessionId.trim().isEmpty ? null : sessionId.trim();
    } else {
      throw const FormatException('Saved booking request is incomplete.');
    }
    return (
      idempotencyKey: idempotencyKey,
      requestPayload: requestPayload,
      cancelRequested: decoded['cancel_requested'] == true,
      sessionId: parsedSessionId,
    );
  }

  Future<void> requestPendingBidSessionCancellation() async {
    final pending = await readPendingBidSessionCreation();
    if (pending == null || pending.cancelRequested) return;
    await savePendingBidSessionCreation(
      idempotencyKey: pending.idempotencyKey,
      requestPayload: pending.requestPayload,
      cancelRequested: true,
      sessionId: pending.sessionId,
    );
  }

  Future<void> attachPendingBidSessionId(String sessionId) async {
    final pending = await readPendingBidSessionCreation();
    if (pending == null) return;
    await savePendingBidSessionCreation(
      idempotencyKey: pending.idempotencyKey,
      requestPayload: pending.requestPayload,
      cancelRequested: pending.cancelRequested,
      sessionId: sessionId,
    );
  }

  Future<void> deletePendingBidSessionCreation() async {
    await _deleteKeys(const [StorageKeys.pendingBidSessionCreation]);
  }

  Future<void> savePendingBidSessionCancellationId(String sessionId) async {
    final normalizedSessionId = sessionId.trim();
    if (normalizedSessionId.isEmpty) return;
    await _writeValue(
      key: StorageKeys.pendingBidSessionCancellationId,
      value: normalizedSessionId,
    );
  }

  Future<String?> readPendingBidSessionCancellationId() async {
    final sessionId = await _readValue(
      key: StorageKeys.pendingBidSessionCancellationId,
    );
    final normalizedSessionId = sessionId?.trim();
    return normalizedSessionId == null || normalizedSessionId.isEmpty
        ? null
        : normalizedSessionId;
  }

  Future<void> deletePendingBidSessionCancellationId() async {
    await _deleteKeys(const [StorageKeys.pendingBidSessionCancellationId]);
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
