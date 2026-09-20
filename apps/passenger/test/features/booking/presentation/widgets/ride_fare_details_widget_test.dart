import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger/src/features/booking/booking.dart';
import 'package:passenger/src/features/booking/presentation/widgets/ride_fare_details_widget.dart';

void main() {
  Widget buildSubject({required FareEstimate fareResult}) {
    return MaterialApp(
      theme: EasyRideTheme.main,
      home: Scaffold(
        body: RideFareDetailsWidget(
          passengerName: 'Avery Cruz',
          fareResult: fareResult,
          offeredFare: fareResult.totalFare,
          tipAmount: 0,
          totalFare: fareResult.totalFare,
          onBackPressed: () {},
        ),
      ),
    );
  }

  testWidgets('itemizes dynamic surge multiplier when surge charge exists', (
    tester,
  ) async {
    const fareWithSurge = FareEstimate(
      baseFare: 20,
      distanceCharge: 10,
      timeCharge: 10,
      surgeCharge: 12, // Subtotal is 40. Total with surge is 52 -> 52/40 = 1.3x
      totalFare: 52,
    );

    await tester.pumpWidget(buildSubject(fareResult: fareWithSurge));

    expect(find.text('Dynamic surge (1.3x)'), findsOneWidget);
    expect(find.text('₱12'), findsOneWidget);
  });

  testWidgets('hides surge line when surge charge is zero', (tester) async {
    const fareWithoutSurge = FareEstimate(
      baseFare: 20,
      distanceCharge: 10,
      timeCharge: 10,
      surgeCharge: 0,
      totalFare: 40,
    );

    await tester.pumpWidget(buildSubject(fareResult: fareWithoutSurge));

    expect(find.textContaining('Dynamic surge'), findsNothing);
  });
}
