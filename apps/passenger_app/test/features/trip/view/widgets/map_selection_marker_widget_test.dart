import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:passenger_app/src/features/trip/view/widgets/map_selection_marker_widget.dart';

void main() {
  testWidgets('renders the compact green trip-location marker', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themeData,
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
    expect(MapSelectionMarkerWidget.markerColor, AppTheme.complete);
    expect(
      find.descendant(of: marker, matching: find.byType(CustomPaint)),
      findsOneWidget,
    );

    final semantics = tester.getSemantics(marker);
    expect(semantics.label, 'Selected map location');
  });
}
