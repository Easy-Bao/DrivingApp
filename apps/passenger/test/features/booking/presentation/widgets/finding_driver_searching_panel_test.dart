import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maps/maps.dart';
import 'package:passenger/src/features/booking/presentation/widgets/finding_driver_searching_panel.dart';

void main() {
  const destination = Place(
    id: 'destination-1',
    name: 'Pet Express - Mall Of Asia',
    fullAddress: 'Pet Express - Mall Of Asia, Pacific Drive, Pasay City, Metro Manila, Philippines',
    latitude: 7.83,
    longitude: 123.44,
  );

  testWidgets('renders searching header, booking ID, and copy button', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FindingDriverSearchingPanel(
            message: 'Searching for a driver',
            fare: 27.57,
            destination: destination,
            requestId: '4821',
            requestCreated: true,
            dotAnimation: const AlwaysStoppedAnimation<double>(0),
            onCancelPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('Searching for a driver'), findsOneWidget);
    expect(find.text('Booking ID: BR-4821'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('copy-booking-id-button')),
      findsOneWidget,
    );
  });

  testWidgets(
    'renders location details card with pickup and drop-off information',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FindingDriverSearchingPanel(
              message: 'Searching for a driver',
              fare: 27.57,
              destination: destination,
              pickupAddress: 'Mountain View, California',
              distance: '3.2 km',
              duration: '9 mins',
              requestId: '4821',
              requestCreated: true,
              dotAnimation: const AlwaysStoppedAnimation<double>(0),
              onCancelPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Pickup Location · Now'), findsOneWidget);
      expect(find.text('Mountain View'), findsOneWidget);
      expect(find.text('Mountain View, California'), findsOneWidget);

      expect(find.text('Drop-off Location · 3.2 km · 9 mins'), findsOneWidget);
      expect(find.text('Pet Express - Mall Of Asia'), findsOneWidget);
      expect(
        find.text(
          'Pet Express - Mall Of Asia, Pacific Drive, Pasay City, Metro Manila, Philippines',
        ),
        findsOneWidget,
      );

      // Verify the purple pin icon is present
      expect(find.byIcon(LucideIcons.map_pin), findsOneWidget);
    },
  );

  testWidgets(
    'shows cash fare and cancel booking button which triggers callback',
    (tester) async {
      var canceled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FindingDriverSearchingPanel(
              message: 'Searching for a driver',
              fare: 27.57,
              destination: destination,
              rideType: 'Solo Ride',
              dotAnimation: const AlwaysStoppedAnimation<double>(0),
              onCancelPressed: () => canceled = true,
            ),
          ),
        ),
      );

      expect(find.text('Cash · Solo Ride'), findsOneWidget);
      expect(find.text('₱27.57'), findsOneWidget);

      final cancelBtn = find.text('Cancel booking');
      expect(cancelBtn, findsOneWidget);
      await tester.tap(cancelBtn);
      await tester.pump();
      expect(canceled, isTrue);
    },
  );

  testWidgets('copy button copies booking ID to clipboard', (tester) async {
    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (methodCall) async {
        if (methodCall.method == 'Clipboard.setData') {
          copiedText =
              (methodCall.arguments as Map<dynamic, dynamic>)['text']
                  as String?;
        }
        return null;
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FindingDriverSearchingPanel(
            message: 'Searching for a driver',
            fare: 27.57,
            destination: destination,
            requestId: 'BR-4821',
            dotAnimation: const AlwaysStoppedAnimation<double>(0),
            onCancelPressed: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('copy-booking-id-button')));
    await tester.pump();

    expect(copiedText, 'BR-4821');
  });
}
