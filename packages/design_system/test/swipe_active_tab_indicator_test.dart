import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:design_system/design_system.dart';

void main() {
  test('selection progress is finite and limited to adjacent tabs', () {
    expect(SwipeActiveTabIndicator.selectionProgress(0.5, 0), 0.5);
    expect(SwipeActiveTabIndicator.selectionProgress(0.5, 1), 0.5);
    expect(SwipeActiveTabIndicator.selectionProgress(0.5, 2), 0);
    expect(SwipeActiveTabIndicator.selectionProgress(double.nan, 0), 1);
    expect(SwipeActiveTabIndicator.selectionProgress(double.infinity, 0), 1);
  });

  testWidgets('scales from the center and fades with page allocation', (
    tester,
  ) async {
    await tester.pumpWidget(_indicatorAt(0.5));

    final first = find.byKey(const ValueKey<String>('indicator-0'));
    final second = find.byKey(const ValueKey<String>('indicator-1'));

    expect(tester.widget<Transform>(first).transform[0], closeTo(0.675, 0.001));
    expect(
      tester.widget<Transform>(second).transform[0],
      closeTo(0.675, 0.001),
    );
    expect(_capsuleAlpha(tester, first), closeTo(0.5, 0.001));
    expect(_capsuleAlpha(tester, second), closeTo(0.5, 0.001));

    final firstCenter = tester.getCenter(first);
    final firstDecoration = tester.getRect(
      find.descendant(of: first, matching: find.byType(DecoratedBox)),
    );
    expect(firstCenter.dx, closeTo(firstDecoration.center.dx, 0.001));
  });

  testWidgets('only the active tab renders a full-size capsule',
      (tester) async {
    await tester.pumpWidget(_indicatorAt(1));

    final active = find.byKey(const ValueKey<String>('indicator-1'));
    expect(active, findsOneWidget);
    expect(tester.widget<Transform>(active).transform[0], closeTo(1, 0.001));
    expect(_capsuleAlpha(tester, active), closeTo(1, 0.001));
    expect(find.byKey(const ValueKey<String>('indicator-0')), findsNothing);
  });
}

Widget _indicatorAt(double pagePosition) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 240,
          height: 54,
          child: SwipeActiveTabIndicator(
            pagePosition: pagePosition,
            itemCount: 2,
            color: Colors.black,
            capsuleKeyPrefix: 'indicator',
          ),
        ),
      ),
    ),
  );
}

double _capsuleAlpha(WidgetTester tester, Finder capsule) {
  final decoratedBox = tester.widget<DecoratedBox>(
    find.descendant(of: capsule, matching: find.byType(DecoratedBox)),
  );
  return (decoratedBox.decoration as BoxDecoration).color?.a ?? 0;
}
