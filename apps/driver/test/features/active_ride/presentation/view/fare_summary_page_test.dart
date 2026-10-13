import 'package:driver/src/features/active_ride/presentation/view/fare_summary_page.dart';
import 'package:driver/src/features/active_ride/domain/services/ride_payment_completion_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final class const _NoOpRidePaymentCompletionHandler()
    implements RidePaymentCompletionHandler {
  @override
  Future<void> afterCashPayment({required String rideId}) async {}
}

void main() {
  testWidgets('displays trip fares as whole pesos', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FareSummaryPage(
          pickup: 'Pickup',
          dropoff: 'Dropoff',
          duration: '5 min',
          distance: 2.5,
          fare: 29.69,
          ridePaymentCompletionHandler:
              const _NoOpRidePaymentCompletionHandler(),
        ),
      ),
    );

    expect(find.text('₱30'), findsOneWidget);
    expect(find.text('₱29.69'), findsNothing);
  });

  testWidgets('lets the driver record an unpaid cash outcome', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FareSummaryPage(
          pickup: 'Pickup',
          dropoff: 'Dropoff',
          duration: '5 min',
          distance: 2.5,
          fare: 29.69,
          ridePaymentCompletionHandler:
              const _NoOpRidePaymentCompletionHandler(),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('cash-received-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('cash-change-field')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('cash-outcome-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Passenger refused to pay').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('cash-received-field')), findsNothing);
    expect(find.byKey(const ValueKey('cash-change-field')), findsNothing);
    expect(find.text('Record unpaid cash'), findsOneWidget);
    expect(find.textContaining('No cash is recorded.'), findsOneWidget);
  });

  testWidgets('requires a cash outcome before leaving the summary', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FareSummaryPage(
          pickup: 'Pickup',
          dropoff: 'Dropoff',
          duration: '5 min',
          distance: 2.5,
          fare: 29.69,
          ridePaymentCompletionHandler:
              const _NoOpRidePaymentCompletionHandler(),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('cash-summary-back-button')));
    await tester.pumpAndSettle();

    expect(find.text('Cash outcome required'), findsOneWidget);
    expect(find.text('Continue recording'), findsOneWidget);
    expect(find.text('Cash collection'), findsOneWidget);

    await tester.tap(find.text('Continue recording'));
    await tester.pumpAndSettle();

    expect(find.text('Cash outcome required'), findsNothing);
    expect(find.text('Cash collection'), findsOneWidget);
  });

  testWidgets('automatically calculates change when cash received changes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FareSummaryPage(
          pickup: 'Pickup',
          dropoff: 'Dropoff',
          duration: '5 min',
          distance: 2.5,
          fare: 50.0,
          ridePaymentCompletionHandler:
              const _NoOpRidePaymentCompletionHandler(),
        ),
      ),
    );

    // Initial state: received = 50.00, change = 0.00
    final receivedField = find.byKey(const ValueKey('cash-received-field'));
    final changeField = find.byKey(const ValueKey('cash-change-field'));
    expect(find.text('50.00'), findsOneWidget);
    expect(find.text('0.00'), findsOneWidget);

    // Type 100 into cash-received
    await tester.enterText(receivedField, '100');
    await tester.pumpAndSettle();

    final changeInput = tester.widget<TextField>(changeField);
    expect(changeInput.controller?.text, '50.00');

    // Tap Exact chip
    await tester.tap(find.byKey(const ValueKey('chip-exact-fare')));
    await tester.pumpAndSettle();

    final receivedInput = tester.widget<TextField>(receivedField);
    expect(receivedInput.controller?.text, '50.00');
    expect(tester.widget<TextField>(changeField).controller?.text, '0.00');

    // Tap bill chip if available (e.g. ₱100)
    final bill100Chip = find.byKey(const ValueKey('chip-bill-100'));
    if (bill100Chip.evaluate().isNotEmpty) {
      await tester.tap(bill100Chip);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(receivedField).controller?.text,
        '100.00',
      );
      expect(tester.widget<TextField>(changeField).controller?.text, '50.00');
    }
  });
}
