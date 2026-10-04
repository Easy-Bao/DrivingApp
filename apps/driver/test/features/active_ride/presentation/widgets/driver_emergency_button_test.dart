import 'package:design_system/design_system.dart';
import 'package:driver/src/features/active_ride/presentation/widgets/driver_emergency_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('exposes an accessible emergency action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.main,
        home: const Scaffold(body: DriverEmergencyButton()),
      ),
    );

    final button = find.byTooltip('Call emergency services (911)');
    expect(button, findsOneWidget);
    expect(tester.getSize(button).height, 48);
    expect(find.byIcon(Icons.emergency_outlined), findsOneWidget);
  });
}
