import 'package:design_system/design_system.dart';
import 'package:driver/src/features/active_ride/presentation/widgets/driver_emergency_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('exposes an accessible emergency action', (tester) async {
    var emergencyStopCompleted = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.main,
        home: Scaffold(
          body: DriverEmergencyButton(
            onEmergencyStop: (reason, details) async => true,
            onEmergencyStopCompleted: () => emergencyStopCompleted = true,
          ),
        ),
      ),
    );

    final button = find.byTooltip('Call emergency services (911)');
    expect(button, findsOneWidget);
    expect(tester.getSize(button).height, 48);
    expect(find.byIcon(Icons.emergency_outlined), findsOneWidget);
    expect(emergencyStopCompleted, isFalse);
  });

  testWidgets('separates emergency calling from ride termination', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.main,
        home: Scaffold(
          body: DriverEmergencyButton(
            onEmergencyStop: (reason, details) async => true,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Call emergency services (911)'));
    await tester.pumpAndSettle();

    expect(find.text('Call emergency services (911)'), findsOneWidget);
    expect(find.text('End ride for safety'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });
}
