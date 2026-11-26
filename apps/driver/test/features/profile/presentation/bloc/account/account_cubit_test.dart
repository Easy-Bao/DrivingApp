import 'dart:async';

import 'package:driver/src/features/profile/domain/entities/account_snapshot.dart';
import 'package:driver/src/features/profile/domain/repositories/profile_repository.dart';
import 'package:driver/src/features/profile/presentation/bloc/account/account_cubit.dart';
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

  test('keeps isLoading true until remote refresh finishes and uses value equality', () async {
    final completer = Completer<Result<AccountSnapshot, Failure>>();
    var refreshCalls = 0;
    final repository = _ControlledProfileRepository(
      onRefresh: () {
        refreshCalls++;
        return completer.future;
      },
    );
    final cubit = AccountCubit(repository: repository);
    addTearDown(cubit.close);

    final firstLoad = cubit.load();
    expect(cubit.state.account.name, 'Cached Driver');
    expect(cubit.state.isLoading, isTrue);

    await cubit.load();
    expect(refreshCalls, 1);

    completer.complete(
      const Ok(
        AccountSnapshot(name: 'Cached Driver', email: 'cached@example.com'),
      ),
    );
    await firstLoad;

    expect(cubit.state.isLoading, isFalse);
    expect(
      cubit.state.account,
      const AccountSnapshot(name: 'Cached Driver', email: 'cached@example.com'),
    );
  });
}

class _ControlledProfileRepository extends _FakeProfileRepository {
  _ControlledProfileRepository({required this.onRefresh});

  final Future<Result<AccountSnapshot, Failure>> Function() onRefresh;

  @override
  Future<Result<AccountSnapshot, Failure>> refreshAccount() => onRefresh();
}
