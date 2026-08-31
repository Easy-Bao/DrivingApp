import 'package:auth/auth.dart';
import 'package:driver_app/src/features/auth/domain/entities/auth_credentials.dart';

abstract interface class DriverAuthRepository
    implements AuthRepository<DriverAuthCredentials> {}
