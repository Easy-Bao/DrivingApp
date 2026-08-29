import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/features/location/bloc/location_access/location_access_cubit.dart';
import 'package:passenger_app/src/features/location/bloc/location_access/location_access_state.dart';
import 'package:passenger_app/src/features/settings/view/settings_page.dart';
import 'package:shared_ui/shared_ui.dart';

class _MockLocationAccessCubit extends MockCubit<LocationAccessViewState>
    implements LocationAccessCubit {}

void main() {
  testWidgets('shows only completed settings destinations', (tester) async {
    final locationCubit = _MockLocationAccessCubit();
    when(() => locationCubit.state).thenReturn(const LocationAccessReady());
    final themeCubit = ThemeModeCubit(
      initialMode: ThemeMode.system,
      savePreference: (_) async => true,
    );
    addTearDown(themeCubit.close);

    var appearanceTaps = 0;
    var locationTaps = 0;
    var helpTaps = 0;
    var termsTaps = 0;
    var aboutTaps = 0;

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ThemeModeCubit>.value(value: themeCubit),
          BlocProvider<LocationAccessCubit>.value(value: locationCubit),
        ],
        child: MaterialApp(
          theme: EasyRideTheme.light,
          home: SettingsPage(
            onAppearanceTap: () => appearanceTaps++,
            onLocationTap: () => locationTaps++,
            onHelpCenterTap: () => helpTaps++,
            onTermsTap: () => termsTaps++,
            onAboutTap: () => aboutTaps++,
          ),
        ),
      ),
    );

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('System default'), findsOneWidget);
    expect(find.text('Location access'), findsOneWidget);
    expect(find.text('Ready for pickups'), findsOneWidget);
    expect(find.text('Help Center'), findsOneWidget);
    expect(find.text('Terms of Service'), findsOneWidget);
    expect(find.text('About BaoRide'), findsOneWidget);
    expect(find.text('Push Notifications'), findsNothing);
    expect(find.text('Location Sharing'), findsNothing);
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

    expect(appearanceTaps, 1);
    expect(locationTaps, 1);
    expect(helpTaps, 1);
    expect(termsTaps, 1);
    expect(aboutTaps, 1);
    expect(tester.takeException(), isNull);
  });
}
