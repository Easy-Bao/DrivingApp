import 'package:driver_app/src/core/services/secure_session_service.dart';

class SecureStorage {
  final SecureSessionService _secureSessionService;
  SecureStorage(this._secureSessionService);

  Future<void> write(String key, String value) => _secureSessionService.writeSessionKey(key, value);
  Future<String?> read(String key) => _secureSessionService.readSessionKey(key);
  Future<void> delete(String key) => _secureSessionService.deleteSessionKey(key);
}
