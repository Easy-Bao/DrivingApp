import 'package:driver_app/src/features/profile/bloc/account/account_cubit.dart';
import 'package:driver_app/src/features/profile/domain/entities/driver_account_snapshot.dart';
import 'package:driver_app/src/features/profile/domain/repositories/i_driver_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_core/shared_core.dart';

class _FakeDriverProfileRepository implements IDriverProfileRepository {
  const _FakeDriverProfileRepository();

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
