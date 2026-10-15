import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('uses readable supporting text for filter options', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
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
      ThemeData(useMaterial3: true).colorScheme.onSurfaceVariant,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the custom filter sheet and returns a selection', (
    tester,
  ) async {
    TripHistoryFilter? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.main,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showTripHistoryFilterSheet(
                  context: context,
                  selectedFilter: TripHistoryFilter.all,
                );
              },
              child: const Text('Open filter'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open filter'));
    await tester.pumpAndSettle();
    expect(find.text('Filter Trips'), findsOneWidget);
    expect(
      find.text('Choose which trips appear in your history.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancelled Trips'));
    await tester.pumpAndSettle();

    expect(result, TripHistoryFilter.cancelled);
    expect(find.text('Filter Trips'), findsNothing);
  });
}
