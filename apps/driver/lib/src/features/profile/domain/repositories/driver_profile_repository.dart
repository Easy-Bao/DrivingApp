import 'package:driver/src/features/profile/domain/entities/driver_account_snapshot.dart';
import 'package:foundation/foundation.dart';

abstract interface class ProfileRepository {
  AccountSnapshot getCachedAccount();

  Future<Result<AccountSnapshot, Failure>> refreshAccount();

  Future<Result<AccountSnapshot, Failure>> updateAccount({
    required AccountSnapshot currentAccount,
    required String name,
    required String vehicleType,
    required String plateNumber,
  });
}
