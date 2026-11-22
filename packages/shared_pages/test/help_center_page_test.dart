import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_pages/shared_pages.dart';

void main() {
  testWidgets('searches topics and exposes only configured contact actions', (
    tester,
  ) async {
    var emailTaps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
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

  testWidgets('resets selected category when updated topics remove it', (
    tester,
  ) async {
    const initialTopics = [
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
    ];
    const updatedTopics = [
      AppHelpTopic(
        category: 'Account',
        question: 'How do I edit my account?',
        answer: 'Open Account and choose Personal Details.',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: AppHelpCenterPage(onBack: () {}, topics: initialTopics),
      ),
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'Trips'));
    await tester.pump();
    expect(find.text('How do I review a trip?'), findsOneWidget);
    expect(find.text('How do I edit my account?'), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: AppHelpCenterPage(onBack: () {}, topics: updatedTopics),
      ),
    );

    expect(find.text('How do I edit my account?'), findsOneWidget);
  });

  testWidgets(
    'expands answers smoothly without OS touch splash and clears search',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: AppHelpCenterPage(
            onBack: () {},
            topics: const [
              AppHelpTopic(
                category: 'Rides',
                question: 'How do I book a ride?',
                answer: 'Select a destination and confirm.',
              ),
            ],
          ),
        ),
      );

      expect(find.text('Select a destination and confirm.'), findsNothing);
      final topicFinder = find.byKey(
        const ValueKey<String>('help-topic-How do I book a ride?'),
      );
      final topicInkWell = tester.widget<InkWell>(
        find.descendant(of: topicFinder, matching: find.byType(InkWell)),
      );
      expect(topicInkWell.enableFeedback, isFalse);
      expect(topicInkWell.splashFactory, NoSplash.splashFactory);

      await tester.tap(topicFinder);
      await tester.pumpAndSettle();
      expect(find.text('Select a destination and confirm.'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey<String>('help-center-search')),
        'missing',
      );
      await tester.pump();
      expect(find.text('No help topics found'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('help-center-reset-filters')),
      );
      await tester.pumpAndSettle();
      expect(find.text('How do I book a ride?'), findsOneWidget);
    },
  );
}
