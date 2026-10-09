import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maps/maps.dart';
import 'package:passenger/src/features/booking/presentation/widgets/finding_driver_searching_panel.dart';

void main() {
  const destination = Place(
    id: 'destination-1',
    name: 'Destination',
    fullAddress: 'Destination address',
    latitude: 7.83,
    longitude: 123.44,
  );

  testWidgets('keeps searching copy independent of ride type', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FindingDriverSearchingPanel(
            message: 'Finding a driver',
            fare: 100,
            destination: destination,
            dotAnimation: const AlwaysStoppedAnimation<double>(0),
            onCancelPressed: () {},
          ),
        ),
      ),
    );

    expect(
      find.text('We’re checking nearby drivers for your ride.'),
      findsOneWidget,
    );
    expect(find.textContaining('Solo'), findsNothing);
  });
}
