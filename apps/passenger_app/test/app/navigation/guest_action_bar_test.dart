import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/src/app/navigation/guest_action_bar.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  testWidgets('renders guest actions and dispatches authentication intents', (
    tester,
  ) async {
    var signUpPressed = false;
    var signInPressed = false;
    var helpPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.light,
        home: Scaffold(
          bottomNavigationBar: GuestActionBarWidget(
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
    expect(find.text('Sign Up'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);

    await tester.tap(find.text('Sign Up'));
    await tester.tap(find.text('Log In'));
    await tester.tap(find.byType(TextButton));

    expect(signUpPressed, isTrue);
    expect(signInPressed, isTrue);
    expect(helpPressed, isTrue);
  });
}
