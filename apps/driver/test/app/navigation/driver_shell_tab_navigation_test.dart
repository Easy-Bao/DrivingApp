import 'package:driver/src/app/navigation/driver_bottom_navigation.dart';
import 'package:driver/src/app/navigation/driver_navigation_shell.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:design_system/design_system.dart';

void main() {
  test('driver tab coordinator tracks navigation and back history', () {
    final coordinator = TabNavigationCoordinator();
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

  for (final wide in [false, true]) {
    testWidgets(
      'driver navigation is fixed and reserves content space wide=$wide',
      (tester) async {
        tester.view.physicalSize = Size(wide ? 1200 : 360, 800);
        tester.view.devicePixelRatio = 1;
        tester.view.padding = const FakeViewPadding(bottom: 24);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPadding);
        final coordinator = TabNavigationCoordinator();
        addTearDown(coordinator.dispose);
        final router = GoRouter(
          initialLocation: '/dashboard',
          routes: [
            StatefulShellRoute.indexedStack(
              builder: (_, _, shell) => ShellLayout(
                navigationShell: shell,
                navigationCoordinator: coordinator,
              ),
              branches: [
                for (final (index, path) in [
                  'dashboard',
                  'trips',
                  'earnings',
                  'account',
                ].indexed)
                  StatefulShellBranch(
                    routes: [
                      GoRoute(
                        path: '/$path',
                        builder: (_, _) => ColoredBox(
                          key: ValueKey('route-body-$index'),
                          color: Colors.transparent,
                          child: Center(child: Text('Page $index')),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          MaterialApp.router(theme: AppTheme.main, routerConfig: router),
        );
        await tester.pumpAndSettle();
        if (wide) {
          expect(find.byType(DriverBottomNavigation), findsNothing);
          expect(find.byType(ShellNavigationRail), findsOneWidget);
        } else {
          final bar = tester.getRect(find.byType(DriverBottomNavigation));
          expect(bar.left, 0);
          expect(bar.right, 360);
          expect(bar.bottom, 800);
          expect(bar.height, DriverBottomNavigation.height + 24);
          expect(
            tester.getRect(find.byKey(const ValueKey('route-body-0'))).bottom,
            bar.top,
          );
          expect(
            tester
                .widget<AppFloatingTabBar>(find.byType(AppFloatingTabBar))
                .bare,
            isTrue,
          );
          await tester.tap(find.byKey(const ValueKey('driver-tab-item-1')));
          await tester.pumpAndSettle();
          expect(find.text('Page 1'), findsOneWidget);
          expect(coordinator.selectedIndex, 1);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets('driver active tab capsule animates to the selected link', (
    tester,
  ) async {
    var selectedIndex = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 280,
              child: StatefulBuilder(
                builder: (context, setState) => DriverBottomNavigation(
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

    final tabBar = find.byType(DriverBottomNavigation);
    expect(tester.getSize(tabBar).height, DriverBottomNavigation.height);
    expect(
      find.descendant(of: tabBar, matching: find.byType(AnimatedScale)),
      findsNothing,
    );
    void expectStaticDestination(int index, String label) {
      final item = find.byKey(ValueKey<String>('driver-tab-item-$index'));
      final labelWidget = tester.widget<Text>(
        find.descendant(of: item, matching: find.text(label)),
      );
      final iconWidget = tester.widget<Icon>(
        find.descendant(of: item, matching: find.byType(Icon)),
      );
      final inkWell = tester.widget<InkWell>(item);
      expect(
        labelWidget.style?.fontSize,
        AppTheme.main.textTheme.labelMedium?.fontSize,
      );
      expect(labelWidget.style?.fontWeight, FontWeight.w500);
      expect(iconWidget.size, AppSize.navigationIcon);
      expect(inkWell.splashFactory, NoSplash.splashFactory);
      expect(
        inkWell.overlayColor?.resolve({WidgetState.pressed}),
        Colors.transparent,
      );
      expect(
        inkWell.overlayColor?.resolve({WidgetState.hovered}),
        Colors.transparent,
      );
    }

    expectStaticDestination(0, 'Dashboard');
    expectStaticDestination(1, 'Trips');
    expectStaticDestination(2, 'Earnings');
    expectStaticDestination(3, 'Account');
    expect(tester.takeException(), isNull);

    final indicator = find.byKey(
      const ValueKey<String>('driver-tab-indicator'),
    );
    expect(indicator, findsOneWidget);
    double capsuleScale(int index) {
      final capsule = find.byKey(
        ValueKey<String>('driver-tab-indicator-$index'),
      );
      return capsule.evaluate().isEmpty
          ? 0
          : tester.widget<Transform>(capsule).transform[0];
    }

    double capsuleOpacity(int index) {
      final capsule = find.byKey(
        ValueKey<String>('driver-tab-indicator-$index'),
      );
      if (capsule.evaluate().isEmpty) return 0;
      final decoratedBox = tester.widget<DecoratedBox>(
        find.descendant(of: capsule, matching: find.byType(DecoratedBox)),
      );
      return (decoratedBox.decoration as BoxDecoration).color?.a ?? 0;
    }

    final initialEarningsCapsuleScale = capsuleScale(2);

    await tester.tap(find.byKey(const ValueKey<String>('driver-tab-item-2')));
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
            find.byKey(const ValueKey<String>('driver-tab-indicator-2')),
          )
          .dx,
      closeTo(
        tester
            .getCenter(find.byKey(const ValueKey<String>('driver-tab-item-2')))
            .dx,
        0.1,
      ),
    );
  });
}
