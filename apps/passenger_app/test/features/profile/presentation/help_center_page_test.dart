import 'package:passenger_app/src/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/src/features/profile/presentation/help_center_page.dart';

void main() {
  testWidgets('uses the passenger topics without placeholder actions', (
    tester,
  ) async {
    var backCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.data,
        home: HelpCenterPage(onBack: () => backCount++),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('help-center-search')),
      findsOneWidget,
    );
    expect(find.text('How do I book a ride?'), findsOneWidget);
    expect(find.text('How do I enable biometric login?'), findsNothing);
    expect(find.text('coming soon'), findsNothing);
    expect(find.byType(ChoiceChip), findsNWidgets(5));

    await tester.tap(find.byTooltip('Back'));
    expect(backCount, 1);
  });
}
