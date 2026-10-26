import 'package:design_system/design_system.dart';
import 'package:driver/src/features/profile/presentation/bloc/account/account_cubit.dart';
import 'package:driver/src/features/profile/presentation/bloc/account/account_state.dart';
import 'package:driver/src/features/profile/domain/entities/driver_account_snapshot.dart';
import 'package:driver/src/features/profile/presentation/view/driver_personal_details_page.dart';
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
  testWidgets(
    'shows read-only contact details and updates from account state',
    (tester) async {
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

      var wentBack = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.main,
          home: BlocProvider<AccountCubit>.value(
            value: cubit,
            child: PersonalDetailsPage(onBack: () => wentBack = true),
          ),
        ),
      );

      expect(find.text('Personal details'), findsOneWidget);
      expect(find.text('BD'), findsOneWidget);
      expect(find.text('Your contact details'), findsOneWidget);
      expect(find.text('Full name'), findsOneWidget);
      expect(find.text('Bao Driver'), findsOneWidget);
      expect(find.text('Mobile number'), findsOneWidget);
      expect(find.text('+639170000001'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('bao@example.com'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(AppSurfaceCard), findsNothing);
      expect(find.text('Save Changes'), findsNothing);
      expect(find.text('Vehicle Type'), findsNothing);
      expect(
        find.text(
          'Phone number and email are verified account identifiers and can’t be edited here.',
        ),
        findsOneWidget,
      );
      cubit.emit(
        const AccountState(account: AccountSnapshot(name: 'Updated Driver')),
      );
      await tester.pump();
      expect(find.text('Updated Driver'), findsOneWidget);
      expect(find.text('UD'), findsOneWidget);
      expect(find.text('Not provided'), findsNWidgets(2));
      await tester.tap(find.byTooltip('Back'));
      expect(wentBack, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
