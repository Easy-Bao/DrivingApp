import 'package:fpdart/fpdart.dart';
import 'package:passenger/src/features/auth/domain/entities/passenger_session.dart';
import 'package:foundation/foundation.dart';

abstract interface class SessionRepository {
  Future<Either<Failure, PassengerSession>> restoreSession();

  Future<Either<Failure, PassengerSession>> clearSession();
}
