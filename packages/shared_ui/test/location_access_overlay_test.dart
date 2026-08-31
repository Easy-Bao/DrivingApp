import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  testWidgets('preserves the route and opens state-specific settings', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var locationSettingsOpened = false;
    var retried = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.light,
        home: Stack(
          children: [
            const ColoredBox(
              key: ValueKey<String>('underlying-route'),
              color: Colors.white,
              child: Center(child: Text('Current route')),
            ),
            LocationAccessOverlay(
              state: LocationAccessOverlayState.serviceDisabled,
              appName: 'BaoRide',
              onOpenLocationSettings: () => locationSettingsOpened = true,
              onTryAgain: () => retried = true,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Current route'), findsOneWidget);
    expect(find.text('Open Location Settings'), findsOneWidget);
    expect(find.text('Try Again'), findsOneWidget);
    expect(
      tester.getSize(
        find.byKey(const ValueKey<String>('location-access-overlay-sheet')),
      ),
      const Size(320, 320),
    );

    await tester.tap(find.text('Open Location Settings'));
    await tester.tap(find.text('Try Again'));

    expect(locationSettingsOpened, isTrue);
    expect(retried, isTrue);
  });

  testWidgets('uses retry as the only action for requestable permission', (
    tester,
  ) async {
    var retried = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.light,
        home: LocationAccessOverlay(
          state: LocationAccessOverlayState.permissionDenied,
          appName: 'EasyRide',
          onTryAgain: () => retried = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Try Again'), findsOneWidget);
    expect(find.text('Open Location Settings'), findsNothing);
    expect(find.text('Open App Settings'), findsNothing);
    await tester.tap(find.text('Try Again'));
    expect(retried, isTrue);
  });

  testWidgets('shows app settings for permanently denied permission', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.light,
        home: const LocationAccessOverlay(
          state: LocationAccessOverlayState.permissionDeniedForever,
          appName: 'BaoRide',
          onOpenAppSettings: _noop,
          onTryAgain: _noop,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open App Settings'), findsOneWidget);
    expect(find.text('Try Again'), findsOneWidget);
    expect(find.text('Open Location Settings'), findsNothing);
  });
}

void _noop() {}
