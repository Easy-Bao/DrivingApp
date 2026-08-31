import 'package:driver_app/src/features/trip/presentation/fare_summary_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('displays trip fares as whole pesos', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FareSummaryPage(
          pickup: 'Pickup',
          dropoff: 'Dropoff',
          duration: '5 min',
          distance: 2.5,
          fare: 29.69,
        ),
      ),
    );

    expect(find.text('₱30'), findsOneWidget);
    expect(find.text('₱29.69'), findsNothing);
  });
}
