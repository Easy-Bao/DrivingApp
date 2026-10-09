import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger/src/features/booking/presentation/widgets/map_selection_marker.dart';

void main() {
  testWidgets('renders the compact primary trip-location marker', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.main,
        home: const Scaffold(body: Center(child: MapSelectionMarker())),
      ),
    );

    final marker = find.byType(MapSelectionMarker);
    expect(marker, findsOneWidget);
    expect(
      tester.getSize(marker),
      const Size(
        MapSelectionMarker.width,
        MapSelectionMarker.height,
      ),
    );
    expect(
      MapSelectionMarker.markerColor,
      EasyRideTheme.main.colorScheme.onSurface,
    );
    expect(
      find.descendant(of: marker, matching: find.byType(CustomPaint)),
      findsOneWidget,
    );

    final semantics = tester.getSemantics(marker);
    expect(semantics.label, 'Selected map location');
  });
}
