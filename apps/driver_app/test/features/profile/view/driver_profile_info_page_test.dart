import 'package:driver_app/src/features/profile/bloc/account/account_cubit.dart';
import 'package:driver_app/src/features/profile/bloc/account/account_state.dart';
import 'package:driver_app/src/features/profile/domain/entities/driver_account_snapshot.dart';
import 'package:driver_app/src/features/profile/domain/repositories/i_driver_profile_repository.dart';
import 'package:driver_app/src/features/profile/view/driver_profile_info_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui/shared_ui.dart';

class _FakeDriverProfileRepository implements IDriverProfileRepository {
  DriverAccountSnapshot updatedAccount = const DriverAccountSnapshot();

  @override
  DriverAccountSnapshot getCachedAccount() => updatedAccount;

  @override
  Future<Either<Failure, DriverAccountSnapshot>> refreshAccount() async {
    return Right(updatedAccount);
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
    updatedAccount = DriverAccountSnapshot(
      name: name,
      phone: phone,
      email: email,
      vehicleType: vehicleType,
      plateNumber: plateNumber,
      totalTrips: currentAccount.totalTrips,
    );
    return Right(updatedAccount);
  }
}

void main() {
  testWidgets('reveals Save only after an editable driver profile changes', (
    tester,
  ) async {
    final repository = _FakeDriverProfileRepository()
      ..updatedAccount = const DriverAccountSnapshot(
        name: 'Bao Driver',
        phone: '+639170000001',
        email: 'bao@example.com',
        vehicleType: 'Sedan',
        plateNumber: 'ABC-1234',
      );
    final cubit = DriverAccountCubit(repository: repository)
      ..emit(DriverAccountState(account: repository.updatedAccount));
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.light,
        home: BlocProvider<DriverAccountCubit>.value(
          value: cubit,
          child: const DriverProfileInfoPage(),
        ),
      ),
    );

    expect(find.text('Profile Info'), findsOneWidget);
    expect(find.text('+63'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('driver-profile-save')),
      findsNothing,
    );

    await tester.enterText(
      find.byKey(const ValueKey<String>('driver-profile-field-Full Name')),
      'Updated Driver',
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('driver-profile-save')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey<String>('driver-profile-save')));
    await tester.pumpAndSettle();

    expect(repository.updatedAccount.name, 'Updated Driver');
    expect(
      find.byKey(const ValueKey<String>('driver-profile-save')),
      findsNothing,
    );
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });
}
