import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('renders semantic success completion state and actions', (
    tester,
  ) async {
    var primaryTapped = false;
    var secondaryTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: Scaffold(
          body: AppCompletionView(
            title: 'Trip completed',
            message: 'Cash fare has been recorded.',
            summary: const Text('₱180.00'),
            footnote: 'Earnings are updated in your summary.',
            primaryActionLabel: 'Back to dispatch',
            onPrimaryAction: () => primaryTapped = true,
            secondaryActionLabel: 'Report an issue',
            onSecondaryAction: () => secondaryTapped = true,
          ),
        ),
      ),
    );

    expect(find.byIcon(LucideIcons.check), findsOneWidget);
    expect(find.text('Trip completed'), findsOneWidget);
    expect(find.text('Cash fare has been recorded.'), findsOneWidget);
    expect(find.text('₱180.00'), findsOneWidget);
    expect(find.text('Earnings are updated in your summary.'), findsOneWidget);

    await tester.tap(find.text('Back to dispatch'));
    await tester.tap(find.text('Report an issue'));
    expect(primaryTapped, isTrue);
    expect(secondaryTapped, isTrue);
  });

  testWidgets('safety report form uses AppCompletionView on submit', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: Scaffold(
          body: TripSafetyReportForm(
            title: 'Report an issue',
            reasons: const [SafetyReportReason(value: 'other', label: 'Other')],
            onSubmit: (_, _) async => null,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('report-reason-other')));
    await tester.enterText(
      find.byKey(const ValueKey('report-details')),
      'Driver took a wrong turn.',
    );
    await tester.pump();
    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();

    expect(find.byType(AppCompletionView), findsOneWidget);
    expect(find.text('Report received'), findsOneWidget);
    expect(find.byIcon(LucideIcons.check), findsOneWidget);
  });
}
