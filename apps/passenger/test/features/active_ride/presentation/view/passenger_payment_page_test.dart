import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger/src/features/active_ride/domain/entities/ride_snapshot.dart';
import 'package:passenger/src/features/active_ride/presentation/view/passenger_payment_page.dart';

void main() {
  const testRide = RideSnapshot(
    id: 'ride-123',
    pickupName: 'Ayala Center',
    dropoffName: 'IT Park',
    pickupLatitude: 10.3157,
    pickupLongitude: 123.8854,
    dropoffLatitude: 10.3290,
    dropoffLongitude: 123.9062,
    status: 'completed',
    driverId: 'driver-456',
    driverName: 'Juan Dela Cruz',
    plateNumber: 'ABC 1234',
    vehicleType: 'Sedan',
    fareAmount: 18500,
  );

  testWidgets('renders payment details with high contrast primary CTA button', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.main,
        home: const PassengerPaymentPage(ride: testRide),
      ),
    );

    expect(find.text('Trip Completed'), findsOneWidget);
    expect(find.text('Cash Payment'), findsOneWidget);
    expect(find.text('Paid Cash to Driver'), findsOneWidget);
    expect(find.byKey(const ValueKey('payment-total-fare')), findsOneWidget);
    expect(find.text('₱185.00'), findsOneWidget);

    final button = tester.widget<ElevatedButton>(
      find.byKey(const ValueKey('confirm-cash-payment-button')),
    );
    final buttonStyle = button.style;
    final backgroundColor = buttonStyle?.backgroundColor?.resolve({});
    final foregroundColor = buttonStyle?.foregroundColor?.resolve({});

    expect(backgroundColor, EasyRideTheme.main.colorScheme.primary);
    expect(foregroundColor, EasyRideTheme.main.colorScheme.onPrimary);
  });

  testWidgets('renders without vertical overflow on compact 360x640 screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.main,
        home: const PassengerPaymentPage(ride: testRide),
      ),
    );

    expect(find.text('Trip Completed'), findsOneWidget);
    expect(find.text('Paid Cash to Driver'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
