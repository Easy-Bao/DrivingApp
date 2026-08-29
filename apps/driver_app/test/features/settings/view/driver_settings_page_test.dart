import 'package:bloc_test/bloc_test.dart';
import 'package:driver_app/src/features/location/bloc/location_access/driver_location_access_cubit.dart';
import 'package:driver_app/src/features/location/bloc/location_access/driver_location_access_state.dart';
import 'package:driver_app/src/features/settings/view/driver_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_ui/shared_ui.dart';

class _MockDriverLocationAccessCubit
    extends MockCubit<DriverLocationAccessViewState>
    implements DriverLocationAccessCubit {}

void main() {
  testWidgets('shows only completed driver settings destinations', (
    tester,
  ) async {
    final locationCubit = _MockDriverLocationAccessCubit();
    when(
      () => locationCubit.state,
    ).thenReturn(const DriverLocationAccessReady());
    final themeCubit = ThemeModeCubit(
      initialMode: ThemeMode.system,
      savePreference: (_) async => true,
    );
    addTearDown(themeCubit.close);

    var backTaps = 0;
    final destinationTaps = <String>[];

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ThemeModeCubit>.value(value: themeCubit),
          BlocProvider<DriverLocationAccessCubit>.value(value: locationCubit),
        ],
        child: MaterialApp(
          theme: EasyRideTheme.light,
          home: DriverSettingsPage(
            onBack: () => backTaps++,
            onAppearanceTap: () => destinationTaps.add('appearance'),
            onLocationTap: () => destinationTaps.add('location'),
            onHelpCenterTap: () => destinationTaps.add('help'),
            onTermsTap: () => destinationTaps.add('terms'),
            onAboutTap: () => destinationTaps.add('about'),
          ),
        ),
      ),
    );

    expect(find.text('System default'), findsOneWidget);
    expect(find.text('Ready to go online'), findsOneWidget);
    expect(find.text('Help Center'), findsOneWidget);
    expect(find.text('Terms of Service'), findsOneWidget);
    expect(find.text('About BaoRide'), findsOneWidget);
    expect(find.text('Push Notifications'), findsNothing);
    expect(find.text('Privacy Center'), findsNothing);

    for (final label in [
      'Appearance',
      'Location access',
      'Help Center',
      'Terms of Service',
      'About BaoRide',
    ]) {
      await tester.ensureVisible(find.text(label));
      await tester.tap(find.text(label));
      await tester.pump();
    }
    await tester.tap(find.byTooltip('Back'));

    expect(destinationTaps, [
      'appearance',
      'location',
      'help',
      'terms',
      'about',
    ]);
    expect(backTaps, 1);
    expect(tester.takeException(), isNull);
  });
}
