import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/features/home/presentation/widgets/destination_search_hint.dart';

void main() {
  testWidgets('shows five common destination search examples', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HomeDestinationSearchHint())),
    );

    expect(HomeDestinationSearchHint.searchExamples, hasLength(5));
    expect(find.text('Search Robinsons'), findsOneWidget);
  });

  testWidgets('uses the dark theme secondary foreground for contrast', (
    tester,
  ) async {
    final theme = ThemeData.dark(useMaterial3: true);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(body: HomeDestinationSearchHint()),
      ),
    );

    final label = tester.widget<Text>(find.text('Search Robinsons'));
    expect(label.style?.color, theme.colorScheme.onSurfaceVariant);
  });

  testWidgets('moves the next phrase from top to bottom in sync', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HomeDestinationSearchHint(
            changeInterval: Duration(seconds: 1),
            transitionDuration: Duration(milliseconds: 300),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('search-hint-edge-mask')), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 100));

    final currentTop = tester.getTopLeft(find.text('Search Robinsons')).dy;
    final nextTop = tester.getTopLeft(find.text('Search School')).dy;

    expect(find.byKey(const ValueKey('search-hint-edge-mask')), findsOneWidget);
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
            child: HomeDestinationSearchHint(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 5));

    expect(find.text('Search Robinsons'), findsOneWidget);
    expect(find.text('Search School'), findsNothing);
  });

  testWidgets(
    'rotates nearby suggestions randomly without consecutive duplicates',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeDestinationSearchHint(
              suggestions: const [
                'Plaza Luz',
                'Search City Hall',
                'Gaisano Capital',
                'Plaza Luz',
              ],
              random: Random(7),
              changeInterval: const Duration(milliseconds: 500),
              transitionDuration: const Duration(milliseconds: 200),
            ),
          ),
        ),
      );

      final allowed = {
        'Search Plaza Luz',
        'Search City Hall',
        'Search Gaisano Capital',
      };
      String displayedLabel() => tester.widget<Text>(find.byType(Text)).data!;

      final seen = <String>[displayedLabel()];
      expect(allowed, contains(seen.last));

      for (var step = 0; step < 6; step++) {
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 250));
        final next = displayedLabel();
        expect(allowed, contains(next));
        expect(
          next,
          isNot(seen.last),
          reason: 'consecutive nearby hints must not repeat',
        );
        seen.add(next);
      }

      expect(seen.toSet(), allowed);
    },
  );

  testWidgets(
    'glides into nearby suggestions when they arrive asynchronously',
    (tester) async {
      Widget buildWidget(List<String> suggestions) => MaterialApp(
        home: Scaffold(
          body: HomeDestinationSearchHint(
            suggestions: suggestions,
            random: Random(3),
            changeInterval: const Duration(seconds: 5),
            transitionDuration: const Duration(milliseconds: 300),
          ),
        ),
      );

      await tester.pumpWidget(buildWidget(const []));
      expect(find.text('Search Robinsons'), findsOneWidget);

      await tester.pumpWidget(
        buildWidget(const ['Pagadian Rotonda', 'Plaza Luz']),
      );
      await tester.pump(const Duration(milliseconds: 120));
      expect(
        find.byKey(const ValueKey('search-hint-edge-mask')),
        findsOneWidget,
      );

      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Search Robinsons'), findsNothing);
      expect(
        tester.widget<Text>(find.byType(Text)).data,
        anyOf('Search Pagadian Rotonda', 'Search Plaza Luz'),
      );
    },
  );

  testWidgets('pauses rotation timer when TickerMode is disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TickerMode(
            enabled: false,
            child: HomeDestinationSearchHint(
              changeInterval: Duration(milliseconds: 500),
              transitionDuration: Duration(milliseconds: 200),
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Search Robinsons'), findsOneWidget);
    expect(find.byKey(const ValueKey('search-hint-edge-mask')), findsNothing);
  });
}
