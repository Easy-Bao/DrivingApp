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
              onCancelPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Pick up · Now'), findsOneWidget);
      expect(find.text('Mountain View'), findsOneWidget);
      expect(find.text('Mountain View, California'), findsOneWidget);

      expect(find.text('Drop off · 3.2 km · 9 mins'), findsOneWidget);
      expect(find.text('Pet Express - Mall Of Asia'), findsOneWidget);
      expect(
        find.text(
          'Pet Express - Mall Of Asia, Pacific Drive, Pasay City, Metro Manila, Philippines',
        ),
        findsOneWidget,
      );

      expect(find.byIcon(LucideIcons.map_pin), findsOneWidget);
    },
  );

  testWidgets(
    'keeps fare and tip above the total without a money icon and cancels',
    (tester) async {
      var canceled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FindingDriverSearchingPanel(
              message: 'Searching for a driver',
              fare: 27.57,
              destination: destination,
              onCancelPressed: () => canceled = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(LucideIcons.banknote), findsNothing);
      expect(find.text('₱27.57 | Tip: ₱0.00'), findsOneWidget);
      expect(find.text('Total: ₱27.57'), findsOneWidget);
      final breakdownPosition = tester.getTopLeft(
        find.text('₱27.57 | Tip: ₱0.00'),
      );
      final totalPosition = tester.getTopLeft(find.text('Total: ₱27.57'));
      expect(totalPosition.dy, greaterThan(breakdownPosition.dy));
      expect(totalPosition.dx, breakdownPosition.dx);
      for (final icon in [LucideIcons.map_pin, LucideIcons.navigation]) {
        expect(
          tester.widget<Icon>(find.byIcon(icon)).color,
          Theme.of(tester.element(find.byIcon(icon))).colorScheme.onSurface,
        );
      }

      expect(find.textContaining('Solo'), findsNothing);

      final cardFinder = find.byKey(
        const ValueKey<String>('finding-driver-location-card'),
      );
      expect(cardFinder, findsOneWidget);
      expect(
        find.descendant(of: cardFinder, matching: find.text('Total: 27.57')),
        findsNothing,
      );
      expect(
        find.descendant(of: cardFinder, matching: find.text('Total: ₱27.57')),
        findsOneWidget,
      );

      final cancelButton = tester.widget<FilledButton>(
        find.byKey(const ValueKey('cancel-booking-button')),
      );
      final colors = Theme.of(tester.element(find.byType(FilledButton)))
          .colorScheme;
      expect(
        cancelButton.style!.backgroundColor!.resolve({}),
        colors.onSurface,
      );
      expect(cancelButton.style!.foregroundColor!.resolve({}), colors.surface);
      final cancelBtn = find.text('Cancel booking');
      expect(cancelBtn, findsOneWidget);
      await tester.tap(cancelBtn);
      await tester.pump();
      expect(canceled, isTrue);
    },
  );

  testWidgets(
    'shows fare, tip, and total when tip is added and keeps amount inside card',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FindingDriverSearchingPanel(
              message: 'Searching for a driver',
              fare: 37.57,
              baseFare: 27.57,
              tipAmount: 10,
              destination: destination,
              onCancelPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(LucideIcons.banknote), findsNothing);
      expect(find.text('₱27.57 | Tip: ₱10.00'), findsOneWidget);
      expect(find.text('Total: ₱37.57'), findsOneWidget);
      expect(find.textContaining('Solo'), findsNothing);

      final cardFinder = find.byKey(
        const ValueKey<String>('finding-driver-location-card'),
      );
      expect(cardFinder, findsOneWidget);
      expect(
        find.descendant(of: cardFinder, matching: find.text('Total: ₱37.57')),
        findsOneWidget,
      );
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
