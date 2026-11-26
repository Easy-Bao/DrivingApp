import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('AppMapBackButton meets touch target and invokes onPressed', (
    tester,
  ) async {
    var tapped = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: Scaffold(body: AppMapBackButton(onPressed: () => tapped++)),
      ),
    );

    final size = tester.getSize(find.byType(AppMapBackButton));
    expect(size.width, greaterThanOrEqualTo(AppSize.minimumTouchTarget));
    expect(size.height, greaterThanOrEqualTo(AppSize.minimumTouchTarget));

    await tester.tap(find.byType(AppMapBackButton));
    expect(tapped, 1);
  });

  testWidgets('AppBottomSheetContainer renders handle and child', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: const Scaffold(
          body: AppBottomSheetContainer(child: Text('Sheet content')),
        ),
      ),
    );

    expect(find.text('Sheet content'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AppSegmentedTabBar updates selection across options', (
    tester,
  ) async {
    var selected = 'day';
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => AppSegmentedTabBar<String>(
              selectedValue: selected,
              indicatorKey: 'period-indicator',
              itemKeyPrefix: 'period',
              options: const [
                AppSegmentedTabOption(
                  value: 'day',
                  label: 'Day',
                  keySuffix: 'day',
                ),
                AppSegmentedTabOption(
                  value: 'week',
                  label: 'Week',
                  keySuffix: 'week',
                ),
              ],
              onSelected: (value) => setState(() => selected = value),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('period-week')));
    await tester.pumpAndSettle();
    expect(selected, 'week');
  });

  testWidgets('AppFloatingTabBar renders optional header banner above tabs', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: Scaffold(
          bottomNavigationBar: AppFloatingTabBar(
            destinations: const [
              AppTabDestination(icon: Icons.home, label: 'Home'),
              AppTabDestination(icon: Icons.person, label: 'Me'),
            ],
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            itemKeyPrefix: 'tab',
            indicatorKey: 'tab-indicator',
            header: const Padding(
              padding: EdgeInsets.all(8),
              child: Text('Active ride banner'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Active ride banner'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
