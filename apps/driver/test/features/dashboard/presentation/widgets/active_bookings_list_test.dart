import 'package:design_system/design_system.dart';
import 'package:driver/src/features/active_ride/domain/entities/ride_snapshot.dart';
import 'package:driver/src/features/dashboard/presentation/widgets/active_bookings_list.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('shows all five bookings and opens the selected passenger', (
    tester,
  ) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ActiveBookingsList(
              rides: [
                for (var i = 0; i < 5; i++)
                  RideSnapshot(
                    id: 'ride-$i',
                    passengerName: 'Passenger $i',
                    status: i == 0 ? 'in_transit' : 'accepted',
                    pickupName: 'Pickup $i',
                    dropoffName: 'Destination $i',
                  ),
              ],
              onOpen: (id) => selected = id,
            ),
          ),
        ),
      ),
    );
    expect(find.text('5 / 5 active bookings'), findsOneWidget);
    expect(find.text('Onboard\nDestination 0'), findsOneWidget);
    expect(find.text('Awaiting pickup\nPickup 4'), findsOneWidget);
    await tester.ensureVisible(find.text('Passenger 4'));
    final bookingRow = tester.widget<InkWell>(
      find.byKey(const ValueKey<String>('driver-active-booking-ride-4')),
    );
    expect(bookingRow.enableFeedback, isFalse);
    expect(bookingRow.splashFactory, NoSplash.splashFactory);
    await tester.tap(find.text('Passenger 4'));
    expect(selected, 'ride-4');
    expect(tester.takeException(), isNull);
  });
}
