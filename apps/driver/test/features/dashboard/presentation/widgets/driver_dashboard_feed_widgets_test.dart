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
          body: DriverDashboardSectionLabel(label: 'Current Active Trip'),
        ),
      ),
    );

    expect(find.text('Current Active Trip'), findsOneWidget);
    expect(find.textContaining('/5'), findsNothing);
  });

  testWidgets('active trip card does not present a queued-passenger state', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DriverActiveTripCard(
            trip: RideSnapshot(
              id: 'ride-1',
              status: 'accepted',
              pickupName: 'Central Station',
              dropoffName: 'Market Road',
            ),
            isCompletingTrip: false,
            onResume: _noop,
            onComplete: _noop,
          ),
        ),
      ),
    );

    expect(find.textContaining('Queued passenger'), findsNothing);
    expect(find.text('Go to Trip Flow'), findsOneWidget);
  });
}

void _noop() {}
