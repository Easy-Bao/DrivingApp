import 'package:driver/src/app/theme/app_theme.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:driver/src/features/location/presentation/bloc/location_access/driver_location_access_cubit.dart';
import 'package:driver/src/features/location/presentation/bloc/location_access/driver_location_access_state.dart';
import 'package:driver/src/features/settings/presentation/view/driver_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDriverLocationAccessCubit
    extends MockCubit<DriverLocationAccessViewState>
    implements DriverLocationAccessCubit {}

void main() {
  testWidgets('shows only completed driver settings destinations', (
    tester,
  ) async {
    final locationCubit = _MockDriverLocationAccessCubit();
    when(() => locationCubit.state)
        .thenReturn(const DriverLocationAccessReady());
    var backTaps = 0;
    final destinationTaps = <String>[];

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<DriverLocationAccessCubit>.value(value: locationCubit),
        ],
        child: MaterialApp(
          theme: AppTheme.data,
          home: DriverSettingsPage(
            onBack: () => backTaps++,
            onLocationTap: () => destinationTaps.add('location'),
            onHelpCenterTap: () => destinationTaps.add('help'),
            onTermsTap: () => destinationTaps.add('terms'),
            onAboutTap: () => destinationTaps.add('about'),
          ),
        ),
      ),
    );

    expect(find.text('Appearance'), findsNothing);
    expect(find.text('System default'), findsNothing);
    expect(find.text('Ready to go online'), findsOneWidget);
    expect(find.text('Help Center'), findsOneWidget);
    expect(find.text('Terms of Service'), findsOneWidget);
    expect(find.text('About BaoRide'), findsOneWidget);
    expect(find.text('Push Notifications'), findsNothing);
    expect(find.text('Privacy Center'), findsNothing);

    for (final label in [
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

    expect(destinationTaps, ['location', 'help', 'terms', 'about']);
    expect(backTaps, 1);
    expect(tester.takeException(), isNull);
  });
}
