import 'package:driver_app/src/core/theme/app_theme.dart';
import 'package:driver_app/src/shared/widgets/navigationbar/driver_floating_tab_bar.dart';
import 'package:driver_app/src/shared/widgets/navigationbar/driver_navigation_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('driver tab coordinator tracks navigation and back history', () {
    final coordinator = DriverTabNavigationCoordinator();
    addTearDown(coordinator.dispose);

    coordinator.initialize(0);
    expect(coordinator.selectedIndex, 0);
    expect(coordinator.canPop, isTrue);

    coordinator.commit(1);
    coordinator.commit(2);
    expect(coordinator.selectedIndex, 2);
    expect(coordinator.canPop, isFalse);

    expect(coordinator.goBackToPreviousTab(), 1);
    expect(coordinator.goBackToPreviousTab(), 0);
    expect(coordinator.canPop, isTrue);
  });

  testWidgets('driver active tab capsule animates to the selected link', (
    tester,
  ) async {
    var selectedIndex = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themeData,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 280,
              child: StatefulBuilder(
                builder: (context, setState) => DriverFloatingTabBar(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() => selectedIndex = index);
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final tabBar = find.byType(DriverFloatingTabBar);
    expect(tester.getSize(tabBar).height, DriverFloatingTabBar.height);
    expect(
      find.descendant(of: tabBar, matching: find.byType(AnimatedScale)),
      findsNothing,
    );
    void expectStaticDestination(int index, String label) {
      final item = find.byKey(
        ValueKey<String>('driver-floating-tab-item-$index'),
      );
      final labelWidget = tester.widget<Text>(
        find.descendant(of: item, matching: find.text(label)),
      );
      final iconWidget = tester.widget<Icon>(
        find.descendant(of: item, matching: find.byType(Icon)),
      );
      expect(labelWidget.style?.fontSize, 10);
      expect(labelWidget.style?.fontWeight, FontWeight.w500);
      expect(iconWidget.size, 18);
    }

    expectStaticDestination(0, 'Dashboard');
    expectStaticDestination(1, 'Trips');
    expectStaticDestination(2, 'Earnings');
    expectStaticDestination(3, 'Account');
    expect(tester.takeException(), isNull);

    final indicator = find.byKey(
      const ValueKey<String>('driver-floating-tab-indicator'),
    );
    final initialPosition = tester.getTopLeft(indicator).dx;

    await tester.tap(
      find.byKey(const ValueKey<String>('driver-floating-tab-item-2')),
    );
    await tester.pump();
    expect(selectedIndex, 2);
    expect(tester.getTopLeft(indicator).dx, closeTo(initialPosition, 0.1));

    await tester.pump(const Duration(milliseconds: 160));
    final middlePosition = tester.getTopLeft(indicator).dx;
    expect(middlePosition, greaterThan(initialPosition));

    await tester.pumpAndSettle();
    final finalPosition = tester.getTopLeft(indicator).dx;
    expect(finalPosition, greaterThan(middlePosition));
    expectStaticDestination(0, 'Dashboard');
    expectStaticDestination(2, 'Earnings');
    expect(
      tester.getCenter(indicator).dx,
      closeTo(
        tester
            .getCenter(
              find.byKey(const ValueKey<String>('driver-floating-tab-item-2')),
            )
            .dx,
        0.1,
      ),
    );
  });
}
