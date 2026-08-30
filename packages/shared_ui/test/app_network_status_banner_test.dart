import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

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
                AppNetworkStatusBanner(isVisible: true),
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
    } finally {
      semantics.dispose();
    }
  });
}
