import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:design_system/design_system.dart';

void main() {
  testWidgets('searches topics and exposes only configured contact actions', (
    tester,
  ) async {
    var emailTaps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.light,
        home: AppHelpCenterPage(
          onBack: () {},
          onEmailSupport: () => emailTaps++,
          topics: const [
            AppHelpTopic(
              category: 'Trips',
              question: 'How do I review a trip?',
              answer: 'Open Trips and choose a completed ride.',
            ),
            AppHelpTopic(
              category: 'Account',
              question: 'How do I edit my account?',
              answer: 'Open Account and choose Personal Details.',
            ),
          ],
        ),
      ),
    );

    expect(find.text('Email support'), findsOneWidget);
    expect(find.text('Call support'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey<String>('help-center-search')),
      'account',
    );
    await tester.pump();

    expect(find.text('How do I edit my account?'), findsOneWidget);
    expect(find.text('How do I review a trip?'), findsNothing);

    await tester.tap(find.text('Email support'));
    expect(emailTaps, 1);
  });
}
