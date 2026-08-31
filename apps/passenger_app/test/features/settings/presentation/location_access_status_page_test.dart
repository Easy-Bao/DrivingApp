import 'package:passenger_app/src/app/theme/app_theme.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:maps/maps.dart';
import 'package:passenger_app/src/features/location/presentation/bloc/location_access/location_access_cubit.dart';
import 'package:passenger_app/src/features/location/presentation/bloc/location_access/location_access_state.dart';
import 'package:passenger_app/src/features/settings/presentation/location_access_status_page.dart';

class _MockLocationAccessCubit extends MockCubit<LocationAccessViewState>
    implements LocationAccessCubit {}

void main() {
  testWidgets('opens the correct settings action for a disabled service', (
    tester,
  ) async {
    final cubit = _MockLocationAccessCubit();
    when(() => cubit.state).thenReturn(
      const LocationAccessUnavailable(
        accessState: LocationAccessState.serviceDisabled,
      ),
    );
    when(cubit.enable).thenAnswer((_) async {});
    when(cubit.refresh).thenAnswer((_) async {});

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.data,
        home: BlocProvider<LocationAccessCubit>.value(
          value: cubit,
          child: LocationAccessStatusPage(onBack: () {}),
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
