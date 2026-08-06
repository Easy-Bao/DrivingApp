import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:passenger_app/src/shared/widgets/navigationbar/guest_action_bar_widget.dart';

void main() {
  testWidgets('renders guest actions and dispatches authentication intents', (
    tester,
  ) async {
    var signUpPressed = false;
    var signInPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themeData,
        home: Scaffold(
          bottomNavigationBar: GuestActionBarWidget(
            onSignUp: () => signUpPressed = true,
            onSignIn: () => signInPressed = true,
          ),
        ),
      ),
    );

    expect(find.text('Sign in to book rides'), findsOneWidget);
    expect(find.text('Sign up'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);

    await tester.tap(find.text('Sign up'));
    await tester.tap(find.text('Log in'));

    expect(signUpPressed, isTrue);
    expect(signInPressed, isTrue);
  });
}
