import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/auth/domain/entities/auth_credentials.dart';
import 'package:passenger/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:passenger/src/features/auth/presentation/bloc/forgot_password/forgot_password_bloc.dart';
import 'package:passenger/src/features/auth/presentation/bloc/sign_in/sign_in_bloc.dart';
import 'package:passenger/src/features/auth/presentation/bloc/sign_up/sign_up_bloc.dart';
import 'package:passenger/src/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:passenger/src/features/auth/presentation/pages/sign_in_page.dart';
import 'package:passenger/src/features/auth/presentation/pages/sign_up_page.dart';

class _UnusedAuthRepository implements AuthRepository {
  @override
  Future<Result<AuthCredentials, Failure>> authenticate({
    required String email,
    required String password,
    bool rememberMe = false,
  }) => Future.error(UnimplementedError());

  @override
  Future<Result<Map<String, dynamic>, Failure>> registerPassenger({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) => Future.error(UnimplementedError());

  @override
  Future<Result<AuthCredentials, Failure>> verifyOtp({
    required String email,
    required String code,
  }) => Future.error(UnimplementedError());

  @override
  Future<Result<void, Failure>> requestVerificationCode({
    required String email,
  }) => Future.error(UnimplementedError());

  @override
  Future<Result<void, Failure>> resetPassword({required String email}) =>
      Future.error(UnimplementedError());

  @override
  Future<Result<void, Failure>> confirmResetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) => Future.error(UnimplementedError());
}

void main() {
  testWidgets('sign-in and sign-up keep constrained centered form frames', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: SigninPage(signInBloc: SignInBloc(_UnusedAuthRepository())),
      ),
    );
    await tester.pumpAndSettle();
    final signInFieldRect = tester.getRect(find.byType(TextField).first);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: SignupPage(signUpBloc: SignUpBloc(_UnusedAuthRepository())),
      ),
    );
    await tester.pumpAndSettle();
    final signUpFieldRect = tester.getRect(find.byType(TextField).first);

    expect(signInFieldRect.center.dx, 400);
    expect(signUpFieldRect.center.dx, 400);
    expect(signInFieldRect.width, lessThanOrEqualTo(440));
    expect(signUpFieldRect.width, lessThanOrEqualTo(550));
    expect(signInFieldRect.left, greaterThan(24));
  });

  testWidgets(
    'forgot-password form remains scrollable for a reduced viewport',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.main,
          home: ForgotPasswordPage(
            forgotPasswordBloc: ForgotPasswordBloc(_UnusedAuthRepository()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.text('Reset Password'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('sign-in account action stays attached to the form content', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: SigninPage(signInBloc: SignInBloc(_UnusedAuthRepository())),
      ),
    );
    await tester.pumpAndSettle();

    final primaryButton = find.text('Sign in');
    final footerText = find.text('Sign up');
    final tallGap =
        tester.getTopLeft(footerText).dy -
        tester.getBottomRight(primaryButton).dy;

    await tester.binding.setSurfaceSize(const Size(800, 400));
    await tester.pumpAndSettle();

    final compactGap =
        tester.getTopLeft(footerText).dy -
        tester.getBottomRight(primaryButton).dy;
    expect(compactGap, closeTo(tallGap, 0.1));
  });
  testWidgets(
    'passenger sign-in supports autofill and large text with a keyboard',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
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
          home: SigninPage(signInBloc: SignInBloc(_UnusedAuthRepository())),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField).first).autofillHints,
        contains(AutofillHints.username),
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).last).autofillHints,
        contains(AutofillHints.password),
      );
      expect(find.byTooltip('Show password'), findsOneWidget);
      await tester.ensureVisible(find.text('Sign in'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
