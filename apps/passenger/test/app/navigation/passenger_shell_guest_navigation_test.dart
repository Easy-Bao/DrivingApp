import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/app/navigation/guest_action_bar.dart';
import 'package:passenger/src/app/navigation/guest_help_bottom_sheet.dart';

void main() {
  testWidgets('guest auth and help actions open the expected routes', (
    tester,
  ) async {
    Future<void> openHelp(BuildContext context) async {
      final action = await showGuestHelpBottomSheet(context);
      if (!context.mounted || action == null) return;
      switch (action) {
        case GuestHelpAction.resetPassword:
          unawaited(context.push('/auth/forgotpassword'));
        case GuestHelpAction.termsOfService:
          unawaited(context.push('/settings/terms'));
      }
    }

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => Scaffold(
            bottomNavigationBar: GuestActionBar(
              onSignUp: () => unawaited(context.push('/auth/signup')),
              onSignIn: () => unawaited(context.push('/auth/signin')),
              onHelp: () => unawaited(openHelp(context)),
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
        GoRoute(
          path: '/auth/forgotpassword',
          builder: (_, _) => const Text('Forgot password screen'),
        ),
        GoRoute(
          path: '/settings/terms',
          builder: (_, _) => const Text('Terms screen'),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.main, routerConfig: router),
    );
    await tester.pump();

    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();
    expect(find.text('Sign up screen'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in screen'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Need help?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset password'));
    await tester.pumpAndSettle();
    expect(find.text('Forgot password screen'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Need help?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terms of Service'));
    await tester.pumpAndSettle();
    expect(find.text('Terms screen'), findsOneWidget);

    router.dispose();
  });
}
