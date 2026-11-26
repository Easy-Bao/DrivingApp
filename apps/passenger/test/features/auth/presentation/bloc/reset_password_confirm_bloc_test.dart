import 'package:bloc_test/bloc_test.dart';
import 'package:foundation/foundation.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:passenger/src/features/auth/presentation/bloc/reset_password_confirm/reset_password_confirm_bloc.dart';

class _AuthRepository extends Mock implements AuthRepository {}

void main() {
  final repository = _AuthRepository();
  blocTest<ResetPasswordConfirmBloc, ResetPasswordConfirmState>(
    'resends the password reset code through the repository',
    build: () {
      when(() => repository.resetPassword(email: 'person@example.com'))
          .thenAnswer((_) async => const Ok(null));
      return ResetPasswordConfirmBloc(repository);
    },
    act: (bloc) =>
        bloc.add(const ResetPasswordCodeRequested(' Person@Example.com ')),
    expect: () => const [ResetPasswordCodeResending(), ResetPasswordCodeSent()],
  );

  blocTest<ResetPasswordConfirmBloc, ResetPasswordConfirmState>(
    'verifies the reset OTP before allowing password entry',
    build: () {
      when(
        () => repository.verifyResetOtp(
          email: 'person@example.com',
          code: '123456',
        ),
      ).thenAnswer((_) async => const Ok(null));
      return ResetPasswordConfirmBloc(repository);
    },
    act: (bloc) => bloc.add(
      const ResetPasswordCodeVerifyRequested(
        email: ' Person@Example.com ',
        code: '123456',
      ),
    ),
    expect: () => const [
      ResetPasswordCodeVerifying(),
      ResetPasswordCodeVerified(),
    ],
  );

  blocTest<ResetPasswordConfirmBloc, ResetPasswordConfirmState>(
    'blocks invalid reset OTP and reports verification failure',
    build: () {
      when(
        () => repository.verifyResetOtp(
          email: 'person@example.com',
          code: '000000',
        ),
      ).thenAnswer((_) async => const Err(InvalidVerificationCodeFailure()));
      return ResetPasswordConfirmBloc(repository);
    },
    act: (bloc) => bloc.add(
      const ResetPasswordCodeVerifyRequested(
        email: 'person@example.com',
        code: '000000',
      ),
    ),
    expect: () => const [
      ResetPasswordCodeVerifying(),
      ResetPasswordCodeVerificationFailure(
        'That verification code is invalid or expired. Try again.',
      ),
    ],
  );
}
