import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('page header uses the shared hierarchy', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.data,
        home: const Scaffold(
          body: AppPageHeader(title: 'Activity', subtitle: 'Your recent rides'),
        ),
      ),
    );

    final title = tester.widget<Text>(find.text('Activity'));
    final subtitle = tester.widget<Text>(find.text('Your recent rides'));

    expect(title.style?.fontSize, 32);
    expect(title.style?.fontWeight, FontWeight.w800);
    expect(title.style?.color, EasyRideTheme.data.colorScheme.onSurface);
    expect(
      subtitle.style?.color,
      EasyRideTheme.data.colorScheme.onSurfaceVariant,
    );
  });

  testWidgets('navigation rail renders every destination with selection', (
    tester,
  ) async {
    var selectedIndex = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.data,
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: AppNavigationRail(
              destinations: const [
                AppTabDestination(icon: Icons.home, label: 'Home'),
                AppTabDestination(icon: Icons.person, label: 'Account'),
              ],
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) {
                setState(() => selectedIndex = index);
              },
            ),
          ),
        ),
      ),
    );

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex,
      0,
    );

    await tester.tap(find.text('Account'));
    await tester.pump();

    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex,
      1,
    );
  });
}
