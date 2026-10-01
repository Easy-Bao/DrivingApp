import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/auth/domain/entities/auth_credentials.dart';
import 'package:passenger/src/features/auth/domain/repositories/passenger_auth_repository.dart';
import 'package:passenger/src/features/auth/presentation/bloc/forgot_password/forgot_password_bloc.dart';
import 'package:passenger/src/features/auth/presentation/bloc/sign_in/sign_in_bloc.dart';
import 'package:passenger/src/features/auth/presentation/bloc/sign_up/sign_up_bloc.dart';
import 'package:passenger/src/features/auth/presentation/view/forgot_password_page.dart';
import 'package:passenger/src/features/auth/presentation/view/sign_in_page.dart';
import 'package:passenger/src/features/auth/presentation/view/sign_up_page.dart';

class _UnusedAuthRepository implements PassengerAuthRepository {
  @override
  Future<Result<PassengerAuthCredentials, Failure>> authenticate({
    required String email,
    required String password,
  }) => Future.error(UnimplementedError());

  @override
  Future<Result<Map<String, dynamic>, Failure>> registerPassenger({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) => Future.error(UnimplementedError());

  @override
  Future<Result<PassengerAuthCredentials, Failure>> verifyOtp({
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
  testWidgets('sign-in and sign-up share the same centered form frame', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.main,
        home: SigninPage(signInBloc: SignInBloc(_UnusedAuthRepository())),
      ),
    );
    await tester.pumpAndSettle();
    final signInFieldRect = tester.getRect(find.byType(TextField).first);

    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.main,
        home: SignupPage(signUpBloc: SignUpBloc(_UnusedAuthRepository())),
      ),
    );
    await tester.pumpAndSettle();
    final signUpFieldRect = tester.getRect(find.byType(TextField).first);

    expect(signUpFieldRect.left, signInFieldRect.left);
    expect(signUpFieldRect.width, signInFieldRect.width);
    expect(signInFieldRect.left, greaterThan(24));
  });

  testWidgets(
    'forgot-password form remains scrollable for a reduced viewport',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: EasyRideTheme.main,
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
}
