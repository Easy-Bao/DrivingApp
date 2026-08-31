import 'package:driver_app/src/features/profile/domain/entities/driver_account_snapshot.dart';
import 'package:driver_app/src/features/profile/domain/repositories/i_driver_profile_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:foundation/foundation.dart';

class FakeDriverProfileRepository implements IDriverProfileRepository {
  FakeDriverProfileRepository(this.account);

  DriverAccountSnapshot account;

  @override
  DriverAccountSnapshot getCachedAccount() => account;

  @override
  Future<Either<Failure, DriverAccountSnapshot>> refreshAccount() async {
    return Right(account);
  }

  @override
  Future<Either<Failure, DriverAccountSnapshot>> updateAccount({
    required DriverAccountSnapshot currentAccount,
    required String name,
    required String phone,
    required String email,
    required String vehicleType,
    required String plateNumber,
  }) async {
    account = DriverAccountSnapshot(
      name: name,
      phone: phone,
      email: email,
      vehicleType: vehicleType,
      plateNumber: plateNumber,
      ratingLabel: currentAccount.ratingLabel,
      totalTrips: currentAccount.totalTrips,
      completedTrips: currentAccount.completedTrips,
      lifetimeEarnings: currentAccount.lifetimeEarnings,
      averageRating: currentAccount.averageRating,
    );
    return Right(account);
  }
}
