import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:passenger_app/src/app/navigation/guest_action_bar.dart';

void main() {
  testWidgets('guest auth actions open the auth routes', (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => Scaffold(
            bottomNavigationBar: GuestActionBarWidget(
              onSignUp: () => context.push('/auth/signup'),
              onSignIn: () => context.push('/auth/signin'),
              onHelp: () => context.push('/help'),
            ),
          ),
        ),
        GoRoute(
          path: '/auth/signup',
          builder: (_, _) => const Text('Sign up screen'),
        ),
        GoRoute(
          path: '/auth/signin',
          builder: (_, _) => const Text('Sign in screen'),
        ),
        GoRoute(path: '/help', builder: (_, _) => const Text('Help screen')),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();

    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();
    expect(find.text('Sign up screen'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in screen'), findsOneWidget);

    router.dispose();
  });
}
