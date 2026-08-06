import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:passenger_app/src/features/location/view/widgets/location_access_panel.dart';

void main() {
  testWidgets('location prompt exposes enable and skip actions', (
    tester,
  ) async {
    var enablePressed = false;
    var skipPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themeData,
        home: LocationAccessPrompt(
          onEnable: () => enablePressed = true,
          onSkip: () => skipPressed = true,
        ),
      ),
    );

    expect(find.text('Make every pickup easier'), findsOneWidget);
    expect(find.text('Turn on location'), findsOneWidget);
    expect(find.text('Not now'), findsOneWidget);

    await tester.tap(find.text('Turn on location'));
    await tester.tap(find.text('Not now'));

    expect(enablePressed, isTrue);
    expect(skipPressed, isTrue);
  });

  testWidgets('unavailable view exposes manual location and explore actions', (
    tester,
  ) async {
    var updatePressed = false;
    var continuePressed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themeData,
        home: LocationUnavailableView(
          onUpdateLocation: () => updatePressed = true,
          onContinue: () => continuePressed = true,
        ),
      ),
    );

    expect(find.text('We couldn’t locate you'), findsOneWidget);
    expect(find.text('Update location'), findsOneWidget);
    expect(find.text('Continue exploring'), findsOneWidget);

    await tester.tap(find.text('Update location'));
    await tester.tap(find.text('Continue exploring'));

    expect(updatePressed, isTrue);
    expect(continuePressed, isTrue);
  });
}
