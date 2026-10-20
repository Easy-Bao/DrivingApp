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

class _MockProfileDataSource extends Mock implements ProfileRemoteDataSource {}

class _MockSessionService extends Mock implements SessionStore {}

void main() {
  testWidgets('displays personal details with editable name and save action', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final profileDataSource = _MockProfileDataSource();

    final repository = ProfileRepositoryImpl(
      profileDataSource: profileDataSource,
      sessionService: _MockSessionService(),
      preferences: preferences,
    );
    final cubit = AccountCubit(repository: repository)
      ..emit(
        const AccountState(
          account: AccountSnapshot(
            name: 'Driver Name',
            phone: '+639170000001',
            email: 'driver@example.com',
          ),
        ),
      );
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: BlocProvider<AccountCubit>.value(
          value: cubit,
          child: PersonalDetailsPage(onBack: () {}),
        ),
      ),
    );

    expect(
      tester
          .widget<TextField>(
            find.byKey(
              const ValueKey<String>('driver-account-field-Full Name'),
            ),
          )
          .readOnly,
      isFalse,
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey<String>('driver-personal-phone-number')),
          )
          .readOnly,
      isTrue,
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey<String>('driver-account-field-Email')),
          )
          .readOnly,
      isTrue,
    );
    expect(
      find.byKey(const ValueKey<String>('driver-account-details-save')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
