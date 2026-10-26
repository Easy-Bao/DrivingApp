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
  testWidgets(
    'contact details remain readable on a small screen with large text',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
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
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(2)),
            child: child!,
          ),
          home: BlocProvider<AccountCubit>.value(
            value: cubit,
            child: PersonalDetailsPage(onBack: () {}),
          ),
        ),
      );

      expect(find.text('Driver Name'), findsOneWidget);
      expect(find.text('+639170000001'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('driver@example.com'), 150);
      expect(find.text('driver@example.com'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Save Changes'), findsNothing);
      await tester.scrollUntilVisible(
        find.text(
          'Phone number and email are verified account identifiers and can’t be edited here.',
        ),
        200,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
