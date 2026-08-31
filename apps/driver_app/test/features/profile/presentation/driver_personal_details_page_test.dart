import 'package:driver_app/src/app/theme/app_theme.dart';
import 'package:driver_app/src/features/profile/presentation/bloc/account/account_cubit.dart';
import 'package:driver_app/src/features/profile/presentation/bloc/account/account_state.dart';
import 'package:driver_app/src/features/profile/domain/entities/driver_account_snapshot.dart';
import 'package:driver_app/src/features/profile/presentation/driver_personal_details_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_driver_profile_repository.dart';

void main() {
  testWidgets('updates personal details without exposing vehicle fields', (
    tester,
  ) async {
    final repository = FakeDriverProfileRepository(
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
          child: DriverPersonalDetailsPage(onBack: () {}),
        ),
      ),
    );

    expect(find.text('Personal Details'), findsOneWidget);
    expect(find.text('Vehicle Type'), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('driver-account-details-save')),
      findsNothing,
    );

    await tester.enterText(
      find.byKey(const ValueKey<String>('driver-account-field-Full Name')),
      'Updated Driver',
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('driver-account-details-save')),
    );
    await tester.pumpAndSettle();

    expect(repository.account.name, 'Updated Driver');
    expect(repository.account.vehicleType, 'Sedan');
    expect(
      find.byKey(const ValueKey<String>('driver-account-details-save')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
