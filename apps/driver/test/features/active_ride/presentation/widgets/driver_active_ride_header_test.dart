import 'package:driver/src/features/active_ride/presentation/widgets/driver_active_ride_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'shows navigation and reporting without duplicate details or emergency controls',
    (tester) async {
      var reported = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActiveRideHeader(
              backButton: const BackButton(),
              reportAction: IconButton(
                tooltip: 'Report a safety issue',
                onPressed: () => reported = true,
                icon: const Icon(Icons.flag),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(BackButton), findsOneWidget);
      expect(find.text('Trip details'), findsNothing);
      expect(find.textContaining('Booking ID'), findsNothing);
      expect(find.text('Emergency SOS'), findsNothing);
      await tester.tap(find.byTooltip('Report a safety issue'));
      expect(reported, isTrue);
    },
  );
}
