import 'package:driver/src/app/theme/app_theme.dart';
import 'package:driver/src/features/profile/presentation/bloc/account/account_cubit.dart';
import 'package:driver/src/features/profile/presentation/bloc/account/account_state.dart';
import 'package:driver/src/features/profile/domain/entities/driver_account_snapshot.dart';
import 'package:driver/src/features/profile/presentation/view/driver_vehicle_information_page.dart';
import 'package:driver/src/features/profile/domain/repositories/driver_profile_repository.dart';
import 'package:foundation/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDriverProfileRepository(this.account)
    implements DriverProfileRepository {
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

void main() {
  testWidgets('updates vehicle information without exposing personal fields', (
    tester,
  ) async {
    final repository = _FakeDriverProfileRepository(
      const DriverAccountSnapshot(
        name: 'Bao Driver',
        phone: '+639170000001',
        email: 'bao@example.com',
        vehicleType: 'Sedan',
        plateNumber: 'ABC-1234',
      ),
    );
    final cubit = DriverAccountCubit(repository: repository)
      ..emit(DriverAccountState(account: repository.account));
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.data,
        home: BlocProvider<DriverAccountCubit>.value(
          value: cubit,
          child: DriverVehicleInformationPage(onBack: () {}),
        ),
      ),
    );

    expect(find.text('Vehicle Information'), findsOneWidget);
    expect(find.text('Full Name'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey<String>('driver-account-field-Plate Number')),
      'XYZ-9000',
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('driver-account-details-save')),
    );
    await tester.pumpAndSettle();

    expect(repository.account.plateNumber, 'XYZ-9000');
    expect(repository.account.name, 'Bao Driver');
    expect(tester.takeException(), isNull);
  });
}
