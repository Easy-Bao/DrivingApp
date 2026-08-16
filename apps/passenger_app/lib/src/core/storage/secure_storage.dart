import 'package:passenger_app/src/core/constants/storage_keys.dart';
import 'package:passenger_app/src/core/services/secure_session_service.dart';

class SecureStorage {
  final SecureSessionService _secureSessionService;

  SecureStorage(this._secureSessionService);

  Future<void> write(String key, String value) => switch (key) {
    StorageKeys.jwtToken => _secureSessionService.saveToken(value),
    StorageKeys.refreshToken => _secureSessionService.saveRefreshToken(value),
    StorageKeys.passengerId => _secureSessionService.savePassengerId(value),
    StorageKeys.activeRideId => _secureSessionService.saveActiveRideId(value),
    _ => Future<void>.error(_unsupportedKey(key)),
  };

  Future<String?> read(String key) => switch (key) {
    StorageKeys.jwtToken => _secureSessionService.readToken(),
    StorageKeys.refreshToken => _secureSessionService.readRefreshToken(),
    StorageKeys.passengerId => _secureSessionService.readPassengerId(),
    StorageKeys.activeRideId => _secureSessionService.readActiveRideId(),
    _ => Future<String?>.error(_unsupportedKey(key)),
  };

  Future<void> delete(String key) => switch (key) {
    StorageKeys.jwtToken => _secureSessionService.deleteToken(),
    StorageKeys.refreshToken => _secureSessionService.deleteRefreshToken(),
    StorageKeys.passengerId => _secureSessionService.deletePassengerId(),
    StorageKeys.activeRideId => _secureSessionService.deleteActiveRideId(),
    _ => Future<void>.error(_unsupportedKey(key)),
  };

  ArgumentError _unsupportedKey(String key) => ArgumentError.value(
    key,
    'key',
    'Only session-critical keys may be stored in SecureStorage.',
  );
}
