import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  testWidgets('location prompt exposes enable and skip actions', (
    tester,
  ) async {
    var enablePressed = false;
    var skipPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themeData,
        home: LocationPermissionPage(
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

  testWidgets('location prompt displays a settings return status', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themeData,
        home: LocationPermissionPage(
          onEnable: _noop,
          onSkip: _noop,
          statusMessage:
              'Turn on location in Settings, then return to BaoRide.',
        ),
      ),
    );

    expect(
      find.text('Turn on location in Settings, then return to BaoRide.'),
      findsOneWidget,
    );
  });
}

void _noop() {}
