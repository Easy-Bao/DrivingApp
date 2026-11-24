import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
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

    expect(find.text('Sign up'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Need help?'), findsOneWidget);

    await tester.tap(find.text('Sign up'));
    await tester.tap(find.text('Sign in'));
    await tester.tap(find.text('Need help?'));

    expect(signUpPressed, isTrue);
    expect(signInPressed, isTrue);
    expect(helpPressed, isTrue);

    for (final label in const ['Sign up', 'Sign in']) {
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, label),
      );
      expect(button.style?.enableFeedback, isFalse);
      expect(button.style?.splashFactory, NoSplash.splashFactory);
      expect(
        button.style?.overlayColor?.resolve({WidgetState.pressed}),
        Colors.transparent,
      );
      expect(
        button.style?.overlayColor?.resolve({WidgetState.focused}),
        isNot(Colors.transparent),
      );
    }

    final helpButton = tester.widget<TextButton>(
      find.byKey(const ValueKey<String>('guest-action-bar-help')),
    );
    expect(helpButton.style?.enableFeedback, isFalse);
    expect(helpButton.style?.splashFactory, NoSplash.splashFactory);
    expect(
      helpButton.style?.overlayColor?.resolve({WidgetState.pressed}),
      Colors.transparent,
    );
    expect(
      helpButton.style?.overlayColor?.resolve({WidgetState.focused}),
      isNot(Colors.transparent),
    );
  });

  testWidgets('aligns equal guest buttons and help action above safe area', (
    tester,
  ) async {
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
    final signUp = tester.getRect(find.widgetWithText(FilledButton, 'Sign up'));
    final signIn = tester.getRect(find.widgetWithText(FilledButton, 'Sign in'));
    final help = tester.getRect(
      find.byKey(const ValueKey<String>('guest-action-bar-help')),
    );
    expect(signUp.left, 20);
    expect(signIn.right, 340);
    expect(signUp.size, signIn.size);
    expect(signIn.left - signUp.right, 12);
    expect(signUp.height, greaterThanOrEqualTo(48));
    expect(help.height, greaterThanOrEqualTo(48));
    expect(help.top - signUp.bottom, greaterThanOrEqualTo(8));
    expect(640 - help.bottom, 28);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stacks guest actions cleanly for large text', (tester) async {
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
    final signIn = tester.getRect(find.widgetWithText(FilledButton, 'Sign in'));
    final help = tester.getRect(
      find.byKey(const ValueKey<String>('guest-action-bar-help')),
    );
    expect(signUp.width, signIn.width);
    expect(signIn.top, greaterThan(signUp.bottom));
    expect(help.top, greaterThan(signIn.bottom));
    expect(tester.takeException(), isNull);
  });
}
