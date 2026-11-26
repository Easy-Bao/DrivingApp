import 'package:driver/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:driver/src/features/auth/presentation/bloc/reset_password/reset_password_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;

  setUp(() => repository = _MockAuthRepository());

  Future<List<ResetPasswordState>> run(ResetPasswordEvent event) async {
    final bloc = ResetPasswordBloc(repository);
    final states = <ResetPasswordState>[];
    final subscription = bloc.stream.listen(states.add);
    bloc.add(event);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();
    await bloc.close();
    return states;
  }

  test('submits the emailed code and new password', () async {
    when(
      () => repository.confirmPasswordReset(
        email: 'driver@example.com',
        code: '123456',
        newPassword: 'new-password',
      ),
    ).thenAnswer((_) async => const Ok(null));

    final states = await run(
      const ResetPasswordSubmitted(
        email: ' Driver@Example.com ',
        code: ' 123456 ',
        newPassword: 'new-password',
      ),
    );

    expect(states, const [ResetPasswordLoading(), ResetPasswordSuccess()]);
  });

  test('rejects a short password without calling the server', () async {
    final states = await run(
      const ResetPasswordSubmitted(
        email: 'driver@example.com',
        code: '123456',
        newPassword: 'short',
      ),
    );

    expect(states.single, isA<ResetPasswordFailure>());
    verifyNever(
      () => repository.confirmPasswordReset(
        email: any(named: 'email'),
        code: any(named: 'code'),
        newPassword: any(named: 'newPassword'),
      ),
    );
  });

  test('reports a rejected code', () async {
    when(
      () => repository.confirmPasswordReset(
        email: any(named: 'email'),
        code: any(named: 'code'),
        newPassword: any(named: 'newPassword'),
      ),
    ).thenAnswer((_) async => const Err(ServerFailure('Invalid code')));

    final states = await run(
      const ResetPasswordSubmitted(
        email: 'driver@example.com',
        code: '000000',
        newPassword: 'new-password',
      ),
    );

    expect(states.first, const ResetPasswordLoading());
    expect(states.last, isA<ResetPasswordFailure>());
  });
  test('resends the password reset code through the repository', () async {
    when(() => repository.resetPassword(email: 'driver@example.com'))
        .thenAnswer((_) async => const Ok(null));
    final states = await run(
      const ResetPasswordCodeRequested(' Driver@Example.com '),
    );
    expect(states, const [ResetPasswordResending(), ResetPasswordCodeSent()]);
  });

  test(
    'reports resend failure without advancing into password submission state',
    () async {
      when(() => repository.resetPassword(email: 'driver@example.com'))
          .thenAnswer((_) async => const Err(ServerFailure('Retry later')));
      final states = await run(
        const ResetPasswordCodeRequested('driver@example.com'),
      );
      expect(states, const [
        ResetPasswordResending(),
        ResetPasswordResendFailure(
          'The server could not complete your request. Try again.',
        ),
      ]);
    },
  );

  test(
    'clears verified OTP cache on reset so re-entered codes re-verify',
    () async {
      when(
        () => repository.verifyResetOtp(
          email: 'driver@example.com',
          code: '123456',
        ),
      ).thenAnswer((_) async => const Ok(null));

      final bloc = ResetPasswordBloc(repository);
      addTearDown(bloc.close);

      bloc.add(
        const ResetPasswordCodeVerifyRequested(
          email: 'driver@example.com',
          code: '123456',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state, const ResetPasswordCodeVerified());

      bloc.add(const ResetPasswordCodeVerificationReset());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state, const ResetPasswordInitial());

      bloc.add(
        const ResetPasswordCodeVerifyRequested(
          email: 'driver@example.com',
          code: '123456',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      verify(
        () => repository.verifyResetOtp(
          email: 'driver@example.com',
          code: '123456',
        ),
      ).called(2);
    },
  );

  test(
    'verifies reset OTP before advancing and reports invalid codes',
    () async {
      when(
        () => repository.verifyResetOtp(
          email: 'driver@example.com',
          code: '000000',
        ),
      ).thenAnswer((_) async => const Err(InvalidVerificationCodeFailure()));
      final rejected = await run(
        const ResetPasswordCodeVerifyRequested(
          email: 'driver@example.com',
          code: '000000',
        ),
      );
      expect(rejected, const [
        ResetPasswordCodeVerifying(),
        ResetPasswordCodeVerificationFailure(
          'That verification code is invalid or expired. Try again.',
        ),
      ]);

      when(
        () => repository.verifyResetOtp(
          email: 'driver@example.com',
          code: '123456',
        ),
      ).thenAnswer((_) async => const Ok(null));
      final verified = await run(
        const ResetPasswordCodeVerifyRequested(
          email: ' Driver@Example.com ',
          code: ' 123456 ',
        ),
      );
      expect(verified, const [
        ResetPasswordCodeVerifying(),
        ResetPasswordCodeVerified(),
      ]);
    },
  );
}
