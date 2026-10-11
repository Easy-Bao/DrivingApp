import 'package:design_system/design_system.dart';
import 'package:driver/src/features/profile/data/data_sources/driver_profile_remote_data_source.dart';
import 'package:driver/src/features/profile/data/repositories/driver_profile_repository_impl.dart';
import 'package:driver/src/features/profile/domain/entities/driver_account_snapshot.dart';
import 'package:driver/src/features/profile/presentation/bloc/account/account_cubit.dart';
import 'package:driver/src/features/profile/presentation/bloc/account/account_state.dart';
import 'package:driver/src/features/profile/presentation/view/driver_personal_details_page.dart';
import 'package:driver/src/infrastructure/session/driver_session_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockProfileDataSource extends Mock
    implements DriverProfileRemoteDataSource {}

class _MockSessionService extends Mock implements DriverSessionStore {}

void main() {
  testWidgets('saves personal details before vehicle registration', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final profileDataSource = _MockProfileDataSource();
    when(
      () => profileDataSource.updateProfile(
        data: any<Map<String, dynamic>>(named: 'data'),
      ),
    ).thenAnswer((_) async => const {'name': 'Updated Driver'});

    final repository = DriverProfileRepositoryImpl(
      profileDataSource: profileDataSource,
      sessionService: _MockSessionService(),
      preferences: preferences,
    );
    final cubit = DriverAccountCubit(repository: repository)
      ..emit(
        const DriverAccountState(
          account: DriverAccountSnapshot(name: 'Driver'),
        ),
      );
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.main,
        home: BlocProvider<DriverAccountCubit>.value(
          value: cubit,
          child: DriverPersonalDetailsPage(onBack: () {}),
        ),
      ),
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

    expect(cubit.state.account.name, 'Updated Driver');
    expect(cubit.state.account.vehicleType, isEmpty);
    expect(cubit.state.account.plateNumber, isEmpty);
    verify(
      () => profileDataSource.updateProfile(data: {'name': 'Updated Driver'}),
    ).called(1);
    expect(tester.takeException(), isNull);
  });
}
