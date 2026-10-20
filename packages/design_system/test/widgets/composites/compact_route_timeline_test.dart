import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
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

    expect(find.byIcon(LucideIcons.map_pin), findsOneWidget);
    expect(find.byIcon(LucideIcons.navigation), findsOneWidget);
    expect(find.byIcon(LucideIcons.navigation_2), findsNothing);

    final pickupIcon = tester.getCenter(find.byIcon(LucideIcons.map_pin));
    final pickupLabel = tester.getCenter(find.text('Pickup'));
    final destinationIcon = tester.getCenter(
      find.byIcon(LucideIcons.navigation),
    );
    final destinationLabel = tester.getCenter(find.text('Drop Off'));

    expect((pickupIcon.dy - pickupLabel.dy).abs(), lessThan(8));
    expect((destinationIcon.dy - destinationLabel.dy).abs(), lessThan(8));
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
