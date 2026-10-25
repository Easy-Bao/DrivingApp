import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
// ignore: depend_on_referenced_packages
import 'package:go_router/go_router.dart' show GoRouter;
import 'package:go_router_modular/go_router_modular.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/features/auth/auth_routes.dart';
import 'package:passenger/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:passenger/src/features/auth/presentation/bloc/forgot_password/forgot_password_bloc.dart';
import 'package:passenger/src/features/auth/presentation/bloc/reset_password_confirm/reset_password_confirm_bloc.dart';
import 'package:passenger/src/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:passenger/src/features/auth/presentation/pages/reset_password_confirm_page.dart';

class _AuthRepository extends Mock implements AuthRepository {}

void main() {
  testWidgets(
    'continues from a sent reset code to password confirmation and sign-in',
    (tester) async {
      final repository = _AuthRepository();
      final pending = Completer<Result<void, Failure>>();
      when(() => repository.resetPassword(email: 'passenger@example.com'))
          .thenAnswer((_) => pending.future);
      when(
        () => repository.confirmResetPassword(
          email: 'passenger@example.com',
          code: '123456',
          newPassword: 'new-password',
        ),
      ).thenAnswer((_) async => const Ok(null));
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => ForgotPasswordPage(
              forgotPasswordBloc: ForgotPasswordBloc(repository),
            ),
          ),
          GoRoute(
            path: '/reset',
            name: AuthRoutes.resetPasswordConfirm,
            builder: (_, state) => ResetPasswordConfirmPage(
              email: (state.extra! as Map)['email'] as String,
              code: '',
              resetPasswordConfirmBloc: ResetPasswordConfirmBloc(repository),
            ),
          ),
          GoRoute(
            path: '/signin',
            name: AuthRoutes.signin,
            builder: (_, _) => const Scaffold(body: Text('Ready to sign in')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.main, routerConfig: router),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send code'));
      await tester.pumpAndSettle();
      expect(find.text('Enter your email address.'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'passenger@example.com');
      await tester.ensureVisible(find.text('Send code'));
      await tester.tap(find.text('Send code'));
      await tester.pump();
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
      tester.widget<TextField>(find.byType(TextField)).onSubmitted!(
        'passenger@example.com',
      );
      await tester.pump();
      verify(() => repository.resetPassword(email: 'passenger@example.com'))
          .called(1);
      pending.complete(const Ok(null));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('verification code to passenger@example.com'),
        findsOneWidget,
      );
      expect(find.text('Check your email'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.enterText(find.byType(TextField), '123456');
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Create new password'), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(0), 'new-password');
      await tester.enterText(
        find.byType(TextField).at(1),
        'different-password',
      );
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Reset password'),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Reset password'));
      await tester.pumpAndSettle();
      expect(find.text('Passwords do not match.'), findsOneWidget);
      verifyNever(
        () => repository.confirmResetPassword(
          email: any(named: 'email'),
          code: any(named: 'code'),
          newPassword: any(named: 'newPassword'),
        ),
      );
      await tester.enterText(find.byType(TextField).at(1), 'new-password');
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Reset password'),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Reset password'));
      await tester.pumpAndSettle();
      expect(find.text('Ready to sign in'), findsOneWidget);
      verify(
        () => repository.confirmResetPassword(
          email: 'passenger@example.com',
          code: '123456',
          newPassword: 'new-password',
        ),
      ).called(1);
    },
  );

  for (final resetting in [false, true]) {
    testWidgets(
      'recovery resetting=$resetting supports large text and keyboard insets',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 568));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final repository = _AuthRepository();
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.main,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(2),
                viewInsets: const EdgeInsets.only(bottom: 240),
              ),
              child: child!,
            ),
            home: resetting
                ? ResetPasswordConfirmPage(
                    email: 'passenger@example.com',
                    code: '',
                    resetPasswordConfirmBloc: ResetPasswordConfirmBloc(
                      repository,
                    ),
                  )
                : ForgotPasswordPage(
                    forgotPasswordBloc: ForgotPasswordBloc(repository),
                  ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byType(FilledButton));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
