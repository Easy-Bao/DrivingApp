import 'package:foundation/foundation.dart';
import 'package:passenger/src/core/session/session_store.dart';
import 'package:passenger/src/features/auth/domain/entities/session.dart';
import 'package:passenger/src/features/auth/domain/repositories/session_repository.dart';
import 'package:passenger/src/features/saved_places/data/repositories/saved_places_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class SessionRepositoryImpl implements SessionRepository {
  SessionRepositoryImpl({
    required this._secureSessionService,
    required this._preferences,
  });

  final SessionStore _secureSessionService;
  final SharedPreferences _preferences;
  static const _profileCacheKeys = [
    'passenger_name',
    'passenger_email',
    'passenger_phone',
    'passenger_address',
    'passenger_gender',
    'passenger_avatar_path',
    // Saved places are device-wide, so they must not outlive the account.
    SavedPlacesRepositoryImpl.storageKey,
  ];

  @override
  Future<Result<Session, Failure>> restoreSession() async {
    try {
      final token = await _secureSessionService.readToken();
      final passengerId = await _secureSessionService.readPassengerId();
      final normalizedToken = token?.trim() ?? '';
      final normalizedPassengerId = passengerId?.trim() ?? '';
      if (normalizedToken.isEmpty || normalizedPassengerId.isEmpty) {
        return const Ok(Session.guest());
      }
      return Ok(
        Session.authenticated(
          passengerId: normalizedPassengerId,
          passengerName: _preferences.getString('passenger_name') ?? '',
        ),
      );
    } catch (_) {
      return const Err(
        CacheFailure('Unable to restore the passenger session.'),
      );
    }
  }

  @override
  Future<Result<Session, Failure>> clearSession() async {
    try {
      await Future.wait([
        _secureSessionService.clearAll(),
        for (final key in _profileCacheKeys) _preferences.remove(key),
      ]);
      return const Ok(Session.guest());
    } catch (_) {
      return const Err(CacheFailure('Unable to clear the passenger session.'));
    }
  }
}
