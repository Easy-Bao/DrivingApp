import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  test('dark theme exposes the approved semantic palette', () {
    final theme = EasyRideTheme.dark;
    final scheme = theme.colorScheme;
    final semantic = theme.extension<EasyRideSemanticColors>();

    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, const Color(0xFF090D12));
    expect(scheme.surface, const Color(0xFF121820));
    expect(scheme.surfaceContainerHighest, const Color(0xFF1A222B));
    expect(scheme.primary, const Color(0xFFF4EEE9));
    expect(scheme.onSurface, const Color(0xFFF4EEE9));
    expect(scheme.secondary, const Color(0xFFCDB7AA));
    expect(scheme.onSurfaceVariant, const Color(0xFFA9AFB6));
    expect(scheme.error, const Color(0xFFFFB4AB));
    expect(scheme.outlineVariant.a, closeTo(0.12, 0.01));
    expect(semantic, EasyRideSemanticColors.dark);
    expect(_contrast(scheme.onSurface, scheme.surface), greaterThan(4.5));
    expect(
      _contrast(scheme.onSurfaceVariant, scheme.surface),
      greaterThan(4.5),
    );
  });

  test('light and dark themes share the balanced type scale', () {
    for (final theme in [EasyRideTheme.light, EasyRideTheme.dark]) {
      expect(theme.textTheme.headlineLarge?.fontSize, 28);
      expect(theme.textTheme.headlineLarge?.fontWeight, FontWeight.w800);
      expect(theme.textTheme.titleLarge?.fontSize, 20);
      expect(theme.textTheme.titleMedium?.fontSize, 16);
      expect(theme.textTheme.titleMedium?.fontWeight, FontWeight.w600);
      expect(theme.textTheme.bodyMedium?.fontSize, 14);
      expect(theme.textTheme.bodySmall?.fontSize, 13);
      expect(theme.textTheme.labelLarge?.fontSize, 14);
    }
  });

  testWidgets('dark floating tab bar uses semantic navigation colors', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.light,
        darkTheme: EasyRideTheme.dark,
        themeMode: ThemeMode.dark,
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

    final scheme = EasyRideTheme.dark.colorScheme;
    final indicator = tester.widget<SwipeActiveTabIndicator>(
      find.byType(SwipeActiveTabIndicator),
    );
    final selectedIcon = tester.widget<Icon>(find.byIcon(Icons.home));
    final unselectedIcon = tester.widget<Icon>(find.byIcon(Icons.person));

    expect(indicator.color, scheme.primary.withValues(alpha: 0.16));
    expect(selectedIcon.color, scheme.primary);
    expect(unselectedIcon.color, scheme.onSurfaceVariant);
    expect(tester.widget<Text>(find.text('Home')).style?.color, scheme.primary);
  });

  testWidgets('light floating tab bar keeps a visible active capsule', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.light,
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

    final scheme = EasyRideTheme.light.colorScheme;
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
