import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/features/auth/domain/entities/passenger_session.dart';
import 'package:shared_core/shared_core.dart';

abstract class SessionRepository {
  Future<Either<Failure, PassengerSession>> restoreSession();

  Future<Either<Failure, PassengerSession>> clearSession();
}
