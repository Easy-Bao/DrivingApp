import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service managing the secure persistence of driver credentials and session tokens.
///
/// Encrypts credentials using Keychain on iOS and AES/KeyStore on Android,
/// preventing unauthorized access to JWT tokens and driver identity parameters.
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

  /// Securely caches the unique identifier of the authenticated driver.
  Future<void> writeDriverId(String driverId) async {
    await _storage.write(key: 'driver_id', value: driverId);
  }

  /// Retrieves the unique driver identifier.
  Future<String?> readDriverId() async {
    return await _storage.read(key: 'driver_id');
  }

  /// Clears all encrypted session keys to sign out the driver.
  Future<void> clearSession() async {
    await _storage.deleteAll();
  }
}
