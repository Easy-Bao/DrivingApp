import 'package:driver_app/src/core/services/secure_session_service.dart';

class SecureStorage {
  final SecureSessionService _secureSessionService;
  SecureStorage(this._secureSessionService);

  Future<void> saveToken(String token) =>
      _secureSessionService.saveToken(token);
  Future<String?> readToken() => _secureSessionService.readToken();
  Future<void> clearSession() => _secureSessionService.clearSession();
}
