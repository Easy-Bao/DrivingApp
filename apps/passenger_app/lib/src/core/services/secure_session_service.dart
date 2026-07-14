import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service managing the secure persistence of passenger credentials and session tokens.
///
/// Encrypts credentials using Keychain on iOS and AES/KeyStore on Android,
/// preventing unauthorized access to JWT tokens and passenger identity parameters.
class SecureSessionService {
  final FlutterSecureStorage _storage;

  /// Initializes the secure session database instance with default configuration.
  SecureSessionService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  /// Securely caches the JSON Web Token (JWT) authorizing API requests.
  Future<void> writeAuthToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  /// Retrieves the current JWT authentication token.
  /// Returns null if the session has expired or was cleared.
  Future<String?> readAuthToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  /// Securely caches the unique identifier of the authenticated passenger.
  Future<void> writePassengerId(String passengerId) async {
    await _storage.write(key: 'passenger_id', value: passengerId);
  }

  /// Retrieves the unique passenger identifier.
  Future<String?> readPassengerId() async {
    return await _storage.read(key: 'passenger_id');
  }

  /// Clears all encrypted session keys to sign out the passenger.
  Future<void> clearSession() async {
    await _storage.deleteAll();
  }
}
