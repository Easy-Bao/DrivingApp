import 'package:driver/src/features/profile/presentation/bloc/account/account_cubit.dart';
import 'package:driver/src/features/profile/domain/entities/driver_account_snapshot.dart';
import 'package:driver/src/features/profile/domain/repositories/driver_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:foundation/foundation.dart';

class const _FakeDriverProfileRepository() implements DriverProfileRepository {
  @override
  DriverAccountSnapshot getCachedAccount() => const DriverAccountSnapshot(
    name: 'Cached Driver',
    email: 'cached@example.com',
  );

  @override
  Future<Either<Failure, DriverAccountSnapshot>> refreshAccount() async {
    return const Right(
      DriverAccountSnapshot(
        name: 'Remote Driver',
        email: 'remote@example.com',
        totalTrips: 4,
      ),
    );
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
    return Right(
      DriverAccountSnapshot(
        name: name,
        phone: phone,
        email: email,
        vehicleType: vehicleType,
        plateNumber: plateNumber,
        totalTrips: currentAccount.totalTrips,
      ),
    );
  }
}

void main() {
  test(
    'publishes cached account before the remote refresh completes',
    () async {
      final cubit = DriverAccountCubit(
        repository: const _FakeDriverProfileRepository(),
      );

      await cubit.load();

      expect(cubit.state.account.name, 'Remote Driver');
      expect(cubit.state.account.totalTrips, 4);
      expect(cubit.state.isLoading, isFalse);
      await cubit.close();
    },
  );
}
