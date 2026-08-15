import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/src/features/home/view/widgets/pending_booking_banner_widget.dart';

void main() {
  testWidgets('hides a pending booking from guests', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PendingBookingBannerWidget(
            isAuthenticated: false,
            destinationName: 'Stanford Faculty Club',
            onContinue: () {},
            onDismiss: () {},
          ),
        ),
      ),
    );

    expect(find.text('Continue your booking'), findsNothing);
    expect(find.text('Stanford Faculty Club'), findsNothing);
    expect(find.text('Continue'), findsNothing);
  });

  testWidgets('shows a pending booking to authenticated passengers', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PendingBookingBannerWidget(
            isAuthenticated: true,
            destinationName: 'Stanford Faculty Club',
            onContinue: () {},
            onDismiss: () {},
          ),
        ),
      ),
    );

    expect(find.text('Continue your booking'), findsOneWidget);
    expect(find.text('Stanford Faculty Club'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
