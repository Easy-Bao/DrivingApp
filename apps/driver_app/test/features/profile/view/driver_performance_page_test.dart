import 'package:driver_app/src/features/profile/bloc/account/account_cubit.dart';
import 'package:driver_app/src/features/profile/bloc/account/account_state.dart';
import 'package:driver_app/src/features/profile/domain/entities/driver_account_snapshot.dart';
import 'package:driver_app/src/features/profile/view/driver_performance_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

import '../helpers/fake_driver_profile_repository.dart';

void main() {
  testWidgets('shows balanced driver performance metrics at compact width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeDriverProfileRepository(
      const DriverAccountSnapshot(
        ratingLabel: '4.8',
        totalTrips: 20,
        completedTrips: 18,
        lifetimeEarnings: 12450.50,
        averageRating: 4.8,
      ),
    );
    final cubit = DriverAccountCubit(repository: repository)
      ..emit(DriverAccountState(account: repository.account));
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.light,
        home: BlocProvider<DriverAccountCubit>.value(
          value: cubit,
          child: DriverPerformancePage(onBack: () {}, onRefresh: () async {}),
        ),
      ),
    );

    expect(find.text('Performance'), findsOneWidget);
    expect(find.text('4.8'), findsOneWidget);
    expect(find.text('90% trip completion'), findsOneWidget);
    expect(find.text('Completed trips'), findsOneWidget);
    expect(find.text('18'), findsOneWidget);
    expect(find.text('Total trips'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
    expect(find.text('Lifetime earnings'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
