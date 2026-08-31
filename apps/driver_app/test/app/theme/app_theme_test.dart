import 'package:design_system/design_system.dart';
import 'package:driver_app/src/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exposes the approved default semantic palette', () {
    final theme = AppTheme.data;
    final scheme = theme.colorScheme;
    final semantic = theme.extension<EasyRideSemanticColors>();

    expect(theme.brightness, Brightness.light);
    expect(theme.scaffoldBackgroundColor, const Color(0xFFF8F9FA));
    expect(scheme.surface, const Color(0xFFFFFFFF));
    expect(scheme.primary, const Color(0xFF100E11));
    expect(scheme.onSurface, const Color(0xFF100E11));
    expect(scheme.secondary, const Color(0xFF8A4F35));
    expect(scheme.onSurfaceVariant, const Color(0xFF5F6670));
    expect(scheme.error, const Color(0xFFB3261E));
    expect(semantic, EasyRideSemanticColors.defaults);
    expect(_contrast(scheme.onSurface, scheme.surface), greaterThan(4.5));
    expect(
      _contrast(scheme.onSurfaceVariant, scheme.surface),
      greaterThan(4.5),
    );
  });

  test('exposes the balanced type scale', () {
    final theme = AppTheme.data;
    expect(theme.textTheme.headlineLarge?.fontSize, 28);
    expect(theme.textTheme.headlineLarge?.fontWeight, FontWeight.w800);
    expect(theme.textTheme.titleLarge?.fontSize, 20);
    expect(theme.textTheme.titleMedium?.fontSize, 16);
    expect(theme.textTheme.titleMedium?.fontWeight, FontWeight.w600);
    expect(theme.textTheme.bodyMedium?.fontSize, 14);
    expect(theme.textTheme.bodySmall?.fontSize, 13);
    expect(theme.textTheme.labelLarge?.fontSize, 14);
  });

  testWidgets('keeps the active tab capsule visible in default mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.data,
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: AppFloatingTabBar(
              destinations: const [
                AppTabDestination(icon: Icons.home, label: 'Home'),
                AppTabDestination(icon: Icons.person, label: 'Account'),
              ],
              selectedIndex: 0,
              onDestinationSelected: (_) {},
              itemKeyPrefix: 'tab',
              indicatorKey: 'indicator',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scheme = AppTheme.data.colorScheme;
    final tabBar = find.byType(AppFloatingTabBar);
    final tabContainer = tester.widget<Container>(
      find.descendant(of: tabBar, matching: find.byType(Container)),
    );
    final tabColor = (tabContainer.decoration! as BoxDecoration).color;
    final indicator = tester.widget<SwipeActiveTabIndicator>(
      find.byType(SwipeActiveTabIndicator),
    );

    expect(tabColor, scheme.surface);
    expect(indicator.color, scheme.surfaceContainerHighest);
    expect(indicator.color, AppDesignTokens.neutral);
    expect(indicator.color, isNot(tabColor));
  });
}

double _contrast(Color foreground, Color background) {
  final lighter = foreground.computeLuminance() + 0.05;
  final darker = background.computeLuminance() + 0.05;
  return lighter > darker ? lighter / darker : darker / lighter;
}
