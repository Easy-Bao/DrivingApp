import 'package:driver/src/features/active_ride/domain/entities/ride_snapshot.dart';
import 'package:driver/src/features/dashboard/presentation/widgets/driver_active_trip_card.dart';
import 'package:driver/src/features/dashboard/presentation/widgets/driver_dashboard_section_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the current-trip label without a capacity count', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DashboardSectionLabel(label: 'Current Active Trip'),
        ),
      ),
    );

    expect(find.text('Current Active Trip'), findsOneWidget);
    expect(find.textContaining('/5'), findsNothing);
  });

  testWidgets('active trip card only offers navigation while in transit', (
    tester,
  ) async {
    var resumeCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActiveTripCard(
            trip: const RideSnapshot(
              id: 'ride-1',
              status: 'in_transit',
              pickupName: 'Central Station',
              dropoffName: 'Market Road',
            ),
            onResume: () => resumeCount++,
          ),
        ),
      ),
    );

    expect(find.textContaining('Queued passenger'), findsNothing);
    expect(find.text('Complete Trip'), findsNothing);
    expect(find.text('Continue Navigation'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);

    await tester.tap(find.text('Continue Navigation'));
    expect(resumeCount, 1);
  });
}
