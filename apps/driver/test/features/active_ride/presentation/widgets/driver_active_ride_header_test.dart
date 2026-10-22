import 'package:driver/src/features/active_ride/presentation/widgets/driver_active_ride_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('keeps navigation leading and safety actions trailing', (
    tester,
  ) async {
    final headerBoundsKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              key: headerBoundsKey,
              width: 480,
              child: ActiveRideHeader(
                bookingReference: '701612345678901',
                padding: const EdgeInsets.symmetric(horizontal: 16),
                backButton: const SizedBox(
                  key: ValueKey<String>('back-control'),
                  width: 48,
                  height: 48,
                  child: Icon(Icons.arrow_back),
                ),
                actions: const [
                  SizedBox(
                    key: ValueKey<String>('emergency-action'),
                    width: 48,
                    height: 48,
                  ),
                  SizedBox(
                    key: ValueKey<String>('safety-action'),
                    width: 48,
                    height: 48,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Booking ID 701612345678901'), findsOneWidget);
    final headerBounds = tester.getRect(find.byKey(headerBoundsKey));
    final backBounds = tester.getRect(
      find.byKey(const ValueKey<String>('back-control')),
    );
    final emergencyBounds = tester.getRect(
      find.byKey(const ValueKey<String>('emergency-action')),
    );
    final safetyBounds = tester.getRect(
      find.byKey(const ValueKey<String>('safety-action')),
    );

    expect(backBounds.left, closeTo(headerBounds.left + 16, 0.5));
    expect(backBounds.center.dx, lessThan(headerBounds.center.dx));
    expect(emergencyBounds.center.dx, lessThan(safetyBounds.center.dx));
    expect(safetyBounds.right, closeTo(headerBounds.right - 16, 0.5));
  });
}
