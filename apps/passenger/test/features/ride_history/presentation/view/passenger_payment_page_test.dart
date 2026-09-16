import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger/src/features/ride_history/domain/entities/ride_history.dart';
import 'package:passenger/src/features/ride_history/presentation/view/passenger_payment_page.dart';

void main() {
  const testRide = RideHistory(
    id: 'ride-123',
    pickup: 'Ayala Center',
    destination: 'IT Park',
    pickupLat: 10.3157,
    pickupLng: 123.8854,
    destLat: 10.3290,
    destLng: 123.9062,
    date: '2026-09-16T12:00:00Z',
    price: '₱185.00',
    status: 'COMPLETED',
    driverId: 'driver-456',
    driverName: 'Juan Dela Cruz',
    vehiclePlate: 'ABC 1234',
    vehicleType: 'Sedan',
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
