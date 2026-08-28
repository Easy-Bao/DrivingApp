import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  testWidgets('location prompt exposes enable and skip actions', (
    tester,
  ) async {
    var enablePressed = false;
    var skipPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.light,
        home: LocationPermissionPage(
          onEnable: () => enablePressed = true,
          onSkip: () => skipPressed = true,
        ),
      ),
    );

    expect(find.text('Make every pickup easier'), findsOneWidget);
    expect(find.textContaining('EasyRide uses your location'), findsOneWidget);
    expect(find.text('Turn on location'), findsOneWidget);
    expect(find.text('Not now'), findsOneWidget);

    await tester.tap(find.text('Turn on location'));
    await tester.tap(find.text('Not now'));

    expect(enablePressed, isTrue);
    expect(skipPressed, isTrue);
  });

  testWidgets('location prompt displays a settings return status', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.light,
        home: const LocationPermissionPage(
          onEnable: _noop,
          onSkip: _noop,
          statusMessage:
              'Turn on location in Settings, then return to EasyRide.',
        ),
      ),
    );

    expect(
      find.text('Turn on location in Settings, then return to EasyRide.'),
      findsOneWidget,
    );
  });
}

void _noop() {}
