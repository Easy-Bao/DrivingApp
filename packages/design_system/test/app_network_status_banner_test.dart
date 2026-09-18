import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:design_system/design_system.dart';

void main() {
  testWidgets('shows a non-interactive semantic status when unavailable', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                SizedBox.expand(),
                AppNetworkStatusBanner(isVisible: true, isActiveTracking: true),
              ],
            ),
          ),
        ),
      );

      expect(
        find.text('Connection unavailable. Retrying automatically.'),
        findsOneWidget,
      );
      expect(find.byType(Semantics), findsWidgets);
      expect(find.byType(TextButton), findsNothing);
      expect(
        tester.widget<Material>(find.byType(Material).last).color,
        Theme.of(tester.element(find.byType(Material).last))
            .colorScheme
            .tertiaryContainer,
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('stays hidden outside active tracking', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              SizedBox.expand(),
              AppNetworkStatusBanner(isVisible: true, isActiveTracking: false),
            ],
          ),
        ),
      ),
    );

    expect(
      find.text('Connection unavailable. Retrying automatically.'),
      findsNothing,
    );
  });
}
