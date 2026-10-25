import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders pickup and destination icons', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: const Scaffold(
          body: CompactRouteTimeline(
            pickup: 'Mountain View',
            dropoff: 'Pasadena Inn',
          ),
        ),
      ),
    );

    final pins = find.byType(RouteStopMarker);
    expect(pins, findsNWidgets(2));
    expect(tester.widget<RouteStopMarker>(pins.first).isPickup, isTrue);
    expect(tester.widget<RouteStopMarker>(pins.last).isPickup, isFalse);
    expect(
      find.descendant(of: pins, matching: find.byType(CustomPaint)),
      findsNWidgets(2),
    );

    final pickupCenter = tester.getCenter(pins.first);
    final destinationCenter = tester.getCenter(pins.last);
    expect(pickupCenter.dx, destinationCenter.dx);
    expect(destinationCenter.dy, greaterThan(pickupCenter.dy));
    expect(find.text('Pickup'), findsOneWidget);
    expect(find.text('Drop Off'), findsOneWidget);
  });

  testWidgets('grows to fit scaled route labels and values', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: const Scaffold(
            body: CompactRouteTimeline(
              pickup: 'Mountain View',
              dropoff: 'Pasadena Inn',
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(CompactRouteTimeline)).height,
      greaterThan(82),
    );
    expect(tester.takeException(), isNull);
  });
}
