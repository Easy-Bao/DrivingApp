import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/src/shared/widgets/app_back_button_widget.dart';

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
    expect(find.byType(DecoratedBox), findsOneWidget);
  });
}
