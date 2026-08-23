import 'package:driver_app/src/features/profile/domain/entities/driver_account_snapshot.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_core/shared_core.dart';

abstract class IDriverProfileRepository {
  DriverAccountSnapshot getCachedAccount();

  Future<Either<Failure, DriverAccountSnapshot>> refreshAccount();
}
