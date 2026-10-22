import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maps/maps.dart';
import 'package:passenger/src/features/booking/presentation/widgets/finding_driver_no_driver_panel.dart';

void main() {
  const destination = Place(
    id: 'destination-1',
    name: 'Destination',
    fullAddress: 'Destination address',
    latitude: 7.83,
    longitude: 123.44,
  );

  testWidgets('offers retry and cancel after empty discovery', (tester) async {
    var retryCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FindingDriverNoDriverPanel(
            fare: 100,
            destination: destination,
            pickupAddress: 'Pickup address',
            rideType: 'Solo Ride',
            onRetryPressed: () => retryCount++,
            onCancelPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('No drivers nearby'), findsOneWidget);
    expect(
      find.textContaining('We couldn’t find an available driver nearby'),
      findsOneWidget,
    );
    expect(find.text('Total fare · Cash'), findsOneWidget);
    expect(find.text('Request a ride anyway'), findsNothing);

    await tester.tap(find.text('Retry search'));
    await tester.pump();

    expect(retryCount, 1);
  });
  testWidgets(
    'keeps text actions reachable and route icons neutral on a small screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 560);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var canceled = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.main,
          home: Scaffold(
            body: FindingDriverNoDriverPanel(
              fare: 100,
              destination: destination,
              pickupAddress: 'Pickup address',
              onRetryPressed: () {},
              onCancelPressed: () => canceled = true,
            ),
          ),
        ),
      );
      final card = find.byKey(const ValueKey('finding-driver-trip-context'));
      for (final icon in [LucideIcons.map_pin, LucideIcons.navigation]) {
        final marker = find.descendant(of: card, matching: find.byIcon(icon));
        expect(
          tester.widget<Icon>(marker).color,
          AppTheme.main.colorScheme.onSurface,
        );
      }
      for (final type in [FilledButton, TextButton]) {
        expect(
          find.descendant(of: find.byType(type), matching: find.byType(Icon)),
          findsNothing,
        );
      }
      final scroll = find.byType(SingleChildScrollView);
      for (final label in ['₱100.00', 'Retry search', 'Cancel search']) {
        expect(
          find.descendant(of: scroll, matching: find.text(label)),
          findsOneWidget,
        );
      }
      final fareBottom = tester.getBottomRight(find.text('₱100.00')).dy;
      expect(
        tester.getTopLeft(find.byType(FilledButton)).dy,
        greaterThan(fareBottom),
      );
      await tester.ensureVisible(find.text('Cancel search'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel search'));
      expect(canceled, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
