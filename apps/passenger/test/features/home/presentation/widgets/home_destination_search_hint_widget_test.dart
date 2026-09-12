import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger/src/features/home/presentation/widgets/home_destination_search_hint_widget.dart';

void main() {
  testWidgets('shows five common destination search examples', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HomeDestinationSearchHintWidget()),
      ),
    );

    expect(HomeDestinationSearchHintWidget.searchExamples, hasLength(5));
    expect(find.text('Search Robinsons'), findsOneWidget);
  });

  testWidgets('moves the next phrase from top to bottom in sync', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HomeDestinationSearchHintWidget(
            changeInterval: Duration(seconds: 1),
            transitionDuration: Duration(milliseconds: 300),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 100));

    final currentTop = tester.getTopLeft(find.text('Search Robinsons')).dy;
    final nextTop = tester.getTopLeft(find.text('Search School')).dy;

    expect(find.text('Search Robinsons'), findsOneWidget);
    expect(find.text('Search School'), findsOneWidget);
    expect(nextTop, lessThan(currentTop));
  });

  testWidgets('keeps the first phrase when reduced motion is enabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: HomeDestinationSearchHintWidget(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 5));

    expect(find.text('Search Robinsons'), findsOneWidget);
    expect(find.text('Search School'), findsNothing);
  });
}
