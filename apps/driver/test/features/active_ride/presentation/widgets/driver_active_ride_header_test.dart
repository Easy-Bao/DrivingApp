import 'package:driver/src/features/active_ride/presentation/widgets/driver_active_ride_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows only navigation during an active ride', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ActiveRideHeader(backButton: const BackButton())),
      ),
    );
    expect(find.byType(BackButton), findsOneWidget);
    expect(find.text('Trip details'), findsNothing);
    expect(find.textContaining('Booking ID'), findsNothing);
    expect(find.text('Emergency SOS'), findsNothing);
    expect(find.byTooltip('Report a safety issue'), findsNothing);
  });
}
