import 'package:driver/src/features/profile/domain/entities/driver_account_snapshot.dart';
import 'package:foundation/foundation.dart';

abstract interface class DriverProfileRepository {
  DriverAccountSnapshot getCachedAccount();

  Future<Result<DriverAccountSnapshot, Failure>> refreshAccount();

  Future<Result<DriverAccountSnapshot, Failure>> updateAccount({
    required DriverAccountSnapshot currentAccount,
    required String name,
    required String phone,
    required String email,
    required String vehicleType,
    required String plateNumber,
  });
}
