import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  testWidgets('location gate uses the driver app theme and shared actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.light,
        home: LocationPermissionPage(onEnable: _noop, onSkip: _noop),
      ),
    );

    expect(find.text('Make every pickup easier'), findsOneWidget);
    expect(find.text('Turn on location'), findsOneWidget);
    expect(find.text('Not now'), findsOneWidget);
  });
}

void _noop() {}
