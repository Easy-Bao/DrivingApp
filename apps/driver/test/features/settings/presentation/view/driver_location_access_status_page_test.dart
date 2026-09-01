import 'package:driver/src/app/theme/app_theme.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:maps/maps.dart';
import 'package:driver/src/features/location/presentation/bloc/location_access/driver_location_access_cubit.dart';
import 'package:driver/src/features/location/presentation/bloc/location_access/driver_location_access_state.dart';
import 'package:driver/src/features/settings/presentation/view/driver_location_access_status_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDriverLocationAccessCubit
    extends MockCubit<DriverLocationAccessViewState>
    implements DriverLocationAccessCubit {}

void main() {
  testWidgets('opens phone settings for a disabled location service', (
    tester,
  ) async {
    final cubit = _MockDriverLocationAccessCubit();
    when(() => cubit.state).thenReturn(
      const DriverLocationAccessUnavailable(
        accessState: LocationAccessState.serviceDisabled,
      ),
    );
    when(cubit.enable).thenAnswer((_) async {});
    when(cubit.refresh).thenAnswer((_) async {});

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.data,
        home: BlocProvider<DriverLocationAccessCubit>.value(
          value: cubit,
          child: DriverLocationAccessStatusPage(onBack: () {}),
        ),
      ),
    );

    expect(find.text('Location services are off'), findsOneWidget);
    expect(find.text('Open Location Settings'), findsOneWidget);

    await tester.tap(find.text('Open Location Settings'));
    await tester.pump();

    verify(cubit.enable).called(1);
    expect(tester.takeException(), isNull);
  });
}
