import 'package:driver/src/app/theme/app_theme.dart';
import 'package:driver/src/features/help_center/presentation/view/driver_help_center_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('filters typed driver help topics without placeholder contacts', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.data,
        home: DriverHelpCenterPage(onBack: () {}),
      ),
    );

    expect(find.text('Why can’t I go online?'), findsOneWidget);
    expect(find.text('Email support'), findsNothing);
    expect(find.text('Call support'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey<String>('help-center-search')),
      'something unavailable',
    );
    await tester.pump();

    expect(find.text('No help topics found'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
