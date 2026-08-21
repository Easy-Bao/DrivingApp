import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  testWidgets('plain back button has no decorative surface', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AppBackButtonWidget.plain(onPressed: () {})),
      ),
    );

    expect(find.byType(IconButton), findsOneWidget);
    expect(find.byType(DecoratedBox), findsNothing);
  });

  testWidgets('default back button has a decorative surface', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AppBackButtonWidget(onPressed: () {})),
      ),
    );

    expect(find.byType(IconButton), findsOneWidget);
    final decoration =
        tester.widget<DecoratedBox>(find.byType(DecoratedBox)).decoration
            as BoxDecoration;
    expect(decoration.shape, BoxShape.rectangle);
    expect(decoration.borderRadius, isNull);
  });
}
