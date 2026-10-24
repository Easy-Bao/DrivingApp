import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger/src/app/navigation/guest_action_bar.dart';

void main() {
  testWidgets('renders guest actions and dispatches authentication intents', (
    tester,
  ) async {
    var signUpPressed = false;
    var signInPressed = false;
    var helpPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: Scaffold(
          bottomNavigationBar: GuestActionBar(
            onSignUp: () => signUpPressed = true,
            onSignIn: () => signInPressed = true,
            onHelp: () => helpPressed = true,
          ),
        ),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText() == 'Need help? Visit our Help Centre',
      ),
      findsOneWidget,
    );
    expect(find.text('Sign up'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);

    await tester.tap(find.text('Sign up'));
    await tester.tap(find.text('Log in'));
    await tester.tap(find.byType(TextButton));

    expect(signUpPressed, isTrue);
    expect(signInPressed, isTrue);
    expect(helpPressed, isTrue);
  });
  testWidgets(
    'aligns equal guest buttons with a compact help row and safe area',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.main,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(padding: const EdgeInsets.only(bottom: 24)),
            child: child!,
          ),
          home: Scaffold(
            bottomNavigationBar: GuestActionBar(
              onSignUp: () {},
              onSignIn: () {},
              onHelp: () {},
            ),
          ),
        ),
      );
      final signUp = tester.getRect(
        find.widgetWithText(FilledButton, 'Sign up'),
      );
      final signIn = tester.getRect(
        find.widgetWithText(FilledButton, 'Log in'),
      );
      final help = tester.getRect(find.byType(TextButton));
      expect(signUp.left, 20);
      expect(signIn.right, 340);
      expect(signUp.size, signIn.size);
      expect(signIn.left - signUp.right, 12);
      expect(signUp.height, greaterThanOrEqualTo(48));
      expect(help.top - signUp.bottom, 0);
      expect(help.height, greaterThanOrEqualTo(48));
      expect(640 - help.bottom, 28);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('stacks guest actions for large text without clipping help', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          bottomNavigationBar: GuestActionBar(
            onSignUp: () {},
            onSignIn: () {},
            onHelp: () {},
          ),
        ),
      ),
    );
    final signUp = tester.getRect(find.widgetWithText(FilledButton, 'Sign up'));
    final signIn = tester.getRect(find.widgetWithText(FilledButton, 'Log in'));
    expect(signUp.width, signIn.width);
    expect(signIn.top, greaterThan(signUp.bottom));
    expect(tester.takeException(), isNull);
  });
}
