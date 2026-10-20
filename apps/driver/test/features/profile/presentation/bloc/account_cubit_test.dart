import 'package:driver/src/features/profile/presentation/bloc/account/account_cubit.dart';
import 'package:driver/src/features/profile/domain/entities/driver_account_snapshot.dart';
import 'package:driver/src/features/profile/domain/repositories/driver_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

class const _FakeProfileRepository() implements ProfileRepository {
  @override
  AccountSnapshot getCachedAccount() =>
      const AccountSnapshot(name: 'Cached Driver', email: 'cached@example.com');

  @override
  Future<Result<AccountSnapshot, Failure>> refreshAccount() async {
    return const Ok(
      AccountSnapshot(
        name: 'Remote Driver',
        email: 'remote@example.com',
        totalTrips: 4,
      ),
    );
  }

  @override
  Future<Result<AccountSnapshot, Failure>> updateAccount({
    required AccountSnapshot currentAccount,
    required String name,
    required String vehicleType,
    required String plateNumber,
  }) async {
    return Ok(
      AccountSnapshot(
        name: name,
        phone: currentAccount.phone,
        email: currentAccount.email,
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
      final cubit = AccountCubit(repository: const _FakeProfileRepository());

      await cubit.load();

      expect(cubit.state.account.name, 'Remote Driver');
      expect(cubit.state.account.totalTrips, 4);
      expect(cubit.state.isLoading, isFalse);
      await cubit.close();
    },
  );
}
