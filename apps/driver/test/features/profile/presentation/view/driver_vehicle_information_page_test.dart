import 'package:design_system/design_system.dart';
import 'package:driver/src/features/profile/presentation/bloc/account/account_cubit.dart';
import 'package:driver/src/features/profile/presentation/bloc/account/account_state.dart';
import 'package:driver/src/features/profile/domain/entities/driver_account_snapshot.dart';
import 'package:driver/src/features/profile/presentation/view/driver_vehicle_information_page.dart';
import 'package:driver/src/features/profile/domain/repositories/driver_profile_repository.dart';
import 'package:foundation/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeProfileRepository(this.account) implements ProfileRepository {
  AccountSnapshot account;

  @override
  AccountSnapshot getCachedAccount() => account;

  @override
  Future<Result<AccountSnapshot, Failure>> refreshAccount() async {
    return Ok(account);
  }

  @override
  Future<Result<AccountSnapshot, Failure>> updateAccount({
    required AccountSnapshot currentAccount,
    required String name,
    required String vehicleType,
    required String plateNumber,
  }) async {
    account = AccountSnapshot(
      name: name,
      phone: currentAccount.phone,
      email: currentAccount.email,
      vehicleType: vehicleType,
      plateNumber: plateNumber,
      ratingLabel: currentAccount.ratingLabel,
      totalTrips: currentAccount.totalTrips,
      completedTrips: currentAccount.completedTrips,
      lifetimeEarnings: currentAccount.lifetimeEarnings,
      averageRating: currentAccount.averageRating,
    );
    return Ok(account);
  }
}

void main() {
  testWidgets('updates vehicle information without exposing personal fields', (
    tester,
  ) async {
    final repository = _FakeProfileRepository(
      const AccountSnapshot(
        name: 'Bao Driver',
        phone: '+639170000001',
        email: 'bao@example.com',
        vehicleType: 'Sedan',
        plateNumber: 'ABC-1234',
      ),
    );
    final cubit = AccountCubit(repository: repository)
      ..emit(AccountState(account: repository.account));
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: BlocProvider<AccountCubit>.value(
          value: cubit,
          child: VehicleInformationPage(onBack: () {}),
        ),
      ),
    );

    expect(find.text('Vehicle Information'), findsOneWidget);
    expect(find.text('Full Name'), findsNothing);
    expect(
      tester
          .widget<TextField>(
            find.byKey(
              const ValueKey<String>('driver-account-field-Vehicle Type'),
            ),
          )
          .readOnly,
      isFalse,
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(
              const ValueKey<String>('driver-account-field-Plate Number'),
            ),
          )
          .readOnly,
      isFalse,
    );
    expect(
      find.byKey(const ValueKey<String>('driver-account-details-save')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
