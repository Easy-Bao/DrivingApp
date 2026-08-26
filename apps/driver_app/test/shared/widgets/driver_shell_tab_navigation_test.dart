import 'package:driver_app/src/core/theme/app_theme.dart';
import 'package:driver_app/src/shared/widgets/navigationbar/driver_floating_tab_bar.dart';
import 'package:driver_app/src/shared/widgets/navigationbar/driver_navigation_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

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
      final inkWell = tester.widget<InkWell>(item);
      expect(labelWidget.style?.fontSize, AppDesignTokens.navigationLabelSize);
      expect(labelWidget.style?.fontWeight, FontWeight.w500);
      expect(iconWidget.size, AppDesignTokens.navigationIconSize);
      expect(inkWell.splashFactory, NoSplash.splashFactory);
      expect(
        inkWell.overlayColor?.resolve({WidgetState.pressed}),
        AppTheme.surface.withValues(alpha: 0),
      );
      expect(
        inkWell.overlayColor?.resolve({WidgetState.hovered}),
        AppTheme.surface.withValues(alpha: 0),
      );
    }

    expectStaticDestination(0, 'Dashboard');
    expectStaticDestination(1, 'Trips');
    expectStaticDestination(2, 'Earnings');
    expectStaticDestination(3, 'Account');
    expect(tester.takeException(), isNull);

    final indicator = find.byKey(
      const ValueKey<String>('driver-floating-tab-indicator'),
    );
    expect(indicator, findsOneWidget);
    double capsuleScale(int index) {
      final capsule = find.byKey(
        ValueKey<String>('driver-floating-tab-indicator-$index'),
      );
      return capsule.evaluate().isEmpty
          ? 0
          : tester.widget<Transform>(capsule).transform[0];
    }

    double capsuleOpacity(int index) {
      final capsule = find.byKey(
        ValueKey<String>('driver-floating-tab-indicator-$index'),
      );
      if (capsule.evaluate().isEmpty) return 0;
      final decoratedBox = tester.widget<DecoratedBox>(
        find.descendant(of: capsule, matching: find.byType(DecoratedBox)),
      );
      return (decoratedBox.decoration as BoxDecoration).color?.a ?? 0;
    }

    final initialEarningsCapsuleScale = capsuleScale(2);

    await tester.tap(
      find.byKey(const ValueKey<String>('driver-floating-tab-item-2')),
    );
    await tester.pump();
    expect(selectedIndex, 2);
    final initialTargetCapsuleScale = capsuleScale(2);

    await tester.pump(const Duration(milliseconds: 160));
    final middleTargetCapsuleScale = capsuleScale(2);
    expect(middleTargetCapsuleScale, greaterThan(initialTargetCapsuleScale));
    expect(capsuleOpacity(2), greaterThan(0));

    await tester.pumpAndSettle();
    final finalTargetCapsuleScale = capsuleScale(2);
    expect(finalTargetCapsuleScale, greaterThan(middleTargetCapsuleScale));
    expect(finalTargetCapsuleScale, greaterThan(initialEarningsCapsuleScale));
    expectStaticDestination(0, 'Dashboard');
    expectStaticDestination(2, 'Earnings');
    expect(
      tester
          .getCenter(
            find.byKey(
              const ValueKey<String>('driver-floating-tab-indicator-2'),
            ),
          )
          .dx,
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
