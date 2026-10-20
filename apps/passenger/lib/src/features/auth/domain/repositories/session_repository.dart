import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/auth/domain/entities/session.dart';

abstract interface class SessionRepository {
  Future<Result<Session, Failure>> restoreSession();

  Future<Result<Session, Failure>> clearSession();
}
