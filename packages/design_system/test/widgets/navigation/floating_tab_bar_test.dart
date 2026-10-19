import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'renders destinations without overflowing at large text scale factors',
    (tester) async {
      final destinations = [
        const AppTabDestination(icon: Icons.home, label: 'Home'),
        const AppTabDestination(icon: Icons.history, label: 'Activity'),
        const AppTabDestination(icon: Icons.person, label: 'Account'),
      ];

      var selected = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: EasyRideTheme.main,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              bottomNavigationBar: AppFloatingTabBar(
                destinations: destinations,
                selectedIndex: selected,
                onDestinationSelected: (index) => selected = index,
                itemKeyPrefix: 'tab',
                indicatorKey: 'tab-indicator',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Activity'), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);

      await tester.tap(find.text('Activity'));
      await tester.pumpAndSettle();
      expect(selected, 1);
    },
  );
}
