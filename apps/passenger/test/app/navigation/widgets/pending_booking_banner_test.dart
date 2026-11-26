import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/app/navigation/widgets/pending_booking_banner.dart';

void main() {
  testWidgets('hides a pending booking from guests', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PendingBookingBanner(
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
    var continued = 0;
    var dismissed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PendingBookingBanner(
            isAuthenticated: true,
            destinationName: 'Stanford Faculty Club',
            onContinue: () => continued++,
            onDismiss: () => dismissed++,
          ),
        ),
      ),
    );

    expect(find.text('Continue your booking'), findsOneWidget);
    expect(find.text('Stanford Faculty Club'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.tap(find.byKey(const Key('pending-booking-banner-dismiss')));
    expect(continued, 1);
    expect(dismissed, 1);
  });
}
