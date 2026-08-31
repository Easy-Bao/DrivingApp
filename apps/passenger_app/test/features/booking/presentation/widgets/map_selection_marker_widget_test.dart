import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/src/features/booking/presentation/widgets/map_selection_marker_widget.dart';
import 'package:design_system/design_system.dart';

void main() {
  testWidgets('renders the compact green trip-location marker', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.light,
        home: const Scaffold(body: Center(child: MapSelectionMarkerWidget())),
      ),
    );

    final marker = find.byType(MapSelectionMarkerWidget);
    expect(marker, findsOneWidget);
    expect(
      tester.getSize(marker),
      const Size(
        MapSelectionMarkerWidget.width,
        MapSelectionMarkerWidget.height,
      ),
    );
    expect(
      MapSelectionMarkerWidget.markerColor,
      EasyRideSemanticColors.light.success,
    );
    expect(
      find.descendant(of: marker, matching: find.byType(CustomPaint)),
      findsOneWidget,
    );

    final semantics = tester.getSemantics(marker);
    expect(semantics.label, 'Selected map location');
  });
}
