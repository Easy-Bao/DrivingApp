import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger/src/features/active_ride/presentation/widgets/passenger_emergency_button.dart';

void main() {
  testWidgets('separates emergency calling from ride termination', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.main,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showPassengerEmergencyActionSheet(
                context,
                onEmergencyStop: (reason, details) async => true,
              ),
              child: const Text('Open emergency actions'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open emergency actions'));
    await tester.pumpAndSettle();

    expect(find.text('Call emergency services (911)'), findsOneWidget);
    expect(find.text('End ride for safety'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });
}
