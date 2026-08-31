import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:design_system/design_system.dart';

void main() {
  testWidgets('uses readable supporting text for filter options', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.light,
        home: const Scaffold(
          body: TripHistoryFilterSheet(
            selectedFilter: TripHistoryFilter.completed,
          ),
        ),
      ),
    );

    final description = tester.widget<Text>(
      find.text('Completed and cancelled trips'),
    );
    expect(description.style?.fontSize, greaterThanOrEqualTo(12));
    expect(
      description.style?.color,
      EasyRideTheme.light.colorScheme.onSurfaceVariant,
    );
    expect(tester.takeException(), isNull);
  });
}
