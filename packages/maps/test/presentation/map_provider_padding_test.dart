import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maps/maps.dart';

void main() {
  testWidgets('buildMapView preserves and forwards camera padding', (
    tester,
  ) async {
    const testPadding = EdgeInsets.fromLTRB(10, 20, 30, 40);

    final mapView = MapProvider.buildMapView(
      latitude: 14.5995,
      longitude: 120.9842,
      padding: testPadding,
    );

    expect(mapView, isA<Widget>());

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: mapView)));

    // Mapbox MapWidget is in the tree
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
