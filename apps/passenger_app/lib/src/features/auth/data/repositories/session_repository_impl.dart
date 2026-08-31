import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/core/services/secure_session_service.dart';
import 'package:passenger_app/src/features/auth/domain/entities/passenger_session.dart';
import 'package:passenger_app/src/features/auth/domain/repositories/session_repository.dart';
import 'package:foundation/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionRepositoryImpl implements SessionRepository {
  final SecureSessionService _secureSessionService;
  final SharedPreferences _preferences;

  SessionRepositoryImpl({
    required SecureSessionService secureSessionService,
    required SharedPreferences preferences,
  }) : _secureSessionService = secureSessionService,
       _preferences = preferences;

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
      await _secureSessionService.clearSession();
      return const Right(PassengerSession.guest());
    } catch (_) {
      return const Left(CacheFailure('Unable to clear the passenger session.'));
    }
  }
}
