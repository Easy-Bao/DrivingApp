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
  testWidgets('keeps cash controls reachable with keyboard and large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: FareSummaryPage(
          pickup: 'Mountain View',
          dropoff: 'Charleston Park',
          duration: '5 min',
          distance: 2.5,
          fare: 29.69,
          ridePaymentCompletionHandler:
              const _NoOpRidePaymentCompletionHandler(),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Booking ID - 701612345678901'), findsNothing);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('cash-received-field')),
      150,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cash-received-field')));
    tester.view.viewInsets = const FakeViewPadding(bottom: 180);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Confirm cash collected'), findsOneWidget);
    tester.view.resetViewInsets();
  });

  testWidgets('displays trip fares with currency formatting', (tester) async {
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

    expect(find.text('₱29.69'), findsOneWidget);
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

    final receivedField = find.byKey(const ValueKey('cash-received-field'));
    final changeField = find.byKey(const ValueKey('cash-change-field'));
    expect(find.text('50.00'), findsOneWidget);
    expect(find.text('0.00'), findsOneWidget);

    await tester.enterText(receivedField, '100');
    await tester.pumpAndSettle();

    final changeInput = tester.widget<TextField>(changeField);
    expect(changeInput.controller?.text, '50.00');

    await tester.tap(find.byKey(const ValueKey('chip-exact-fare')));
    await tester.pumpAndSettle();

    final receivedInput = tester.widget<TextField>(receivedField);
    expect(receivedInput.controller?.text, '50.00');
    expect(tester.widget<TextField>(changeField).controller?.text, '0.00');

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
