import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/auth/domain/entities/passenger_session.dart';

abstract interface class SessionRepository {
  Future<Result<PassengerSession, Failure>> restoreSession();

  Future<Result<PassengerSession, Failure>> clearSession();
}
