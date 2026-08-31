import 'package:driver_app/src/features/dashboard/presentation/widgets/driver_dashboard/driver_dashboard_feed_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the active ride count instead of a template token', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DriverDashboardSectionLabel.activeRides(activeRideCount: 1),
        ),
      ),
    );

    expect(find.text('Your active rides (1/5)'), findsOneWidget);
    expect(find.textContaining('__'), findsNothing);
  });
}
