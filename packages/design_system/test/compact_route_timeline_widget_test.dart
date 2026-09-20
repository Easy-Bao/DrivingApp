import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders pickup and destination icons', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.main,
        home: const Scaffold(
          body: CompactRouteTimelineWidget(
            pickup: 'Mountain View',
            dropoff: 'Pasadena Inn',
          ),
        ),
      ),
    );

    expect(find.byIcon(LucideIcons.map_pin), findsOneWidget);
    expect(find.byIcon(LucideIcons.navigation), findsOneWidget);
  });
}
