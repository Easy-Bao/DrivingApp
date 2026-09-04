import 'package:foundation/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger/src/features/auth/domain/entities/passenger_session.dart';
import 'package:passenger/src/features/auth/domain/repositories/session_repository.dart';
import 'package:passenger/src/infrastructure/session/passenger_session_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class SessionRepositoryImpl({
  required this._secureSessionService,
  required this._preferences,
}) implements SessionRepository {
  final PassengerSessionStore _secureSessionService;
  final SharedPreferences _preferences;
  static const _profileCacheKeys = [
    'passenger_name',
    'passenger_email',
    'passenger_phone',
    'passenger_address',
    'passenger_gender',
    'passenger_avatar_path',
  ];

  @override
  Future<Either<Failure, PassengerSession>> restoreSession() async {
    try {
      final token = await _secureSessionService.readToken();
      final passengerId = await _secureSessionService.readPassengerId();
      if (token == null ||
          token.isEmpty ||
          passengerId == null ||
          passengerId.isEmpty) {
        return const Right(PassengerSession.guest());
      }
      return Right(
        PassengerSession.authenticated(
          passengerId: passengerId,
          passengerName: _preferences.getString('passenger_name') ?? '',
        ),
      );
    } catch (_) {
      return const Left(
        CacheFailure('Unable to restore the passenger session.'),
      );
    }
  }

  @override
  Future<Either<Failure, PassengerSession>> clearSession() async {
    try {
      await Future.wait([
        _secureSessionService.clearSession(),
        for (final key in _profileCacheKeys) _preferences.remove(key),
      ]);
      return const Right(PassengerSession.guest());
    } catch (_) {
      return const Left(CacheFailure('Unable to clear the passenger session.'));
    }
  }
}
