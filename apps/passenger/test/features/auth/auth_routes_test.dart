import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger/src/features/auth/auth_module.dart';
import 'package:passenger/src/features/auth/auth_routes.dart';
import 'package:passenger/src/features/home/home_routes.dart';

void main() {
  test('root redirect only handles the exact app root', () {
    expect(
      authRootRedirect(Uri.parse(AuthRoutes.rootPath)),
      HomeRoutes.fullHomePath,
    );
    expect(authRootRedirect(Uri.parse(AuthRoutes.signinPath)), isNull);
    expect(authRootRedirect(Uri.parse(AuthRoutes.signupPath)), isNull);
  });

  test('auth form routes enter from opposite sides for the bottom links', () {
    final routes = AuthModule().routes.whereType<ChildRoute>();
    final signInRoute = routes.singleWhere(
      (route) => route.name == AuthRoutes.signin,
    );
    final signUpRoute = routes.singleWhere(
      (route) => route.name == AuthRoutes.signup,
    );

    final signInTransition = signInRoute.transition! as CustomPageTransition;
    final signUpTransition = signUpRoute.transition! as CustomPageTransition;

    expect(signInTransition.fromRight, isFalse);
    expect(signUpTransition.fromRight, isTrue);
  });

  testWidgets('auth routes render their configured entry direction', (
    tester,
  ) async {
    final routes = AuthModule().routes.whereType<ChildRoute>();
    final signInTransition = routes
        .singleWhere((route) => route.name == AuthRoutes.signin)
        .transition!;
    final signUpTransition = routes
        .singleWhere((route) => route.name == AuthRoutes.signup)
        .transition!;
    final router = GoRouter(
      initialLocation: AuthRoutes.signinPath,
      routes: [
        GoRoute(
          path: AuthRoutes.signinPath,
          pageBuilder: (context, state) => signInTransition.build(
            builder: (_, _) => const KeyedSubtree(
              key: ValueKey<String>('sign-in-page'),
              child: Text('Sign in'),
            ),
          )(context, state),
        ),
        GoRoute(
          path: AuthRoutes.signupPath,
          pageBuilder: (context, state) => signUpTransition.build(
            builder: (_, _) => const KeyedSubtree(
              key: ValueKey<String>('sign-up-page'),
              child: Text('Sign up'),
            ),
          )(context, state),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    unawaited(router.push(AuthRoutes.signupPath));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('Sign up'), findsOneWidget);
    _expectEntryOffset(
      tester,
      const ValueKey<String>('sign-up-page'),
      horizontal: 1,
    );
    await tester.pumpAndSettle();

    unawaited(router.push(AuthRoutes.signinPath));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('Sign in'), findsOneWidget);
    _expectEntryOffset(
      tester,
      const ValueKey<String>('sign-in-page'),
      horizontal: -1,
    );
  });
}

void _expectEntryOffset(
  WidgetTester tester,
  ValueKey<String> pageKey, {
  required double horizontal,
}) {
  final slides = tester
      .widgetList<SlideTransition>(
        find.ancestor(
          of: find.byKey(pageKey),
          matching: find.byType(SlideTransition),
        ),
      )
      .toList();
  final offset = slides.first.position.value;
  expect(offset.dx, closeTo(horizontal, 0.01));
  expect(offset.dy, closeTo(0, 0.01));
}
