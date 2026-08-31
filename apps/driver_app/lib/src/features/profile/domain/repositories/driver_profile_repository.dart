import 'package:driver_app/src/features/profile/domain/entities/driver_account_snapshot.dart';
import 'package:fpdart/fpdart.dart';
import 'package:foundation/foundation.dart';

abstract interface class DriverProfileRepository {
  DriverAccountSnapshot getCachedAccount();

  Future<Either<Failure, DriverAccountSnapshot>> refreshAccount();

  Future<Either<Failure, DriverAccountSnapshot>> updateAccount({
    required DriverAccountSnapshot currentAccount,
    required String name,
    required String phone,
    required String email,
    required String vehicleType,
    required String plateNumber,
  });
}
