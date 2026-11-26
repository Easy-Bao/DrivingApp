import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:passenger/src/features/auth/presentation/bloc/verify_otp/verify_otp_bloc.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository authRepository;

  setUp(() {
    authRepository = MockAuthRepository();
  });

  blocTest<VerifyOtpBloc, VerifyOtpState>(
    'requests a new code and restarts the cooldown after a successful resend',
    build: () {
      when(
        () => authRepository.requestVerificationCode(
          email: 'passenger@example.com',
        ),
      ).thenAnswer((_) async => const Ok(null));
      return VerifyOtpBloc(authRepository);
    },
    act: (bloc) => bloc.add(
      const VerifyOtpResendRequested(email: ' Passenger@Example.com '),
    ),
    expect: () => [
      isA<VerifyOtpResending>(),
      isA<VerifyOtpResent>(),
      isA<VerifyOtpTimerTicking>().having(
        (state) => state.secondsRemaining,
        'seconds remaining',
        60,
      ),
    ],
    verify: (_) {
      verify(
        () => authRepository.requestVerificationCode(
          email: 'passenger@example.com',
        ),
      ).called(1);
    },
  );

  blocTest<VerifyOtpBloc, VerifyOtpState>(
    'keeps resend available and sanitizes server errors when resend fails',
    build: () {
      when(
        () =>
            authRepository.requestVerificationCode(email: any(named: 'email')),
      ).thenAnswer(
        (_) async => const Err(ServerFailure('Mail service unavailable.')),
      );
      return VerifyOtpBloc(authRepository);
    },
    act: (bloc) => bloc.add(
      const VerifyOtpResendRequested(email: 'passenger@example.com'),
    ),
    expect: () => [
      isA<VerifyOtpResending>(),
      isA<VerifyOtpResendFailure>()
          .having(
            (state) => state.errorMessage,
            'error message',
            'The server could not complete your request. Try again.',
          )
          .having((state) => state.canResend, 'canResend', isTrue),
    ],
  );

  blocTest<VerifyOtpBloc, VerifyOtpState>(
    'preserves verification failure while the resend countdown ticks to zero',
    build: () {
      when(
        () => authRepository.verifyOtp(
          email: 'passenger@example.com',
          code: '123456',
        ),
      ).thenAnswer(
        (_) async => const Err(
          InvalidVerificationCodeFailure(
            'Invalid verification code. Try again.',
          ),
        ),
      );
      return VerifyOtpBloc(authRepository);
    },
    act: (bloc) async {
      bloc.add(const VerifyOtpTimerTicked(secondsRemaining: 2));
      bloc.add(
        const VerifyOtpSubmitted(
          email: 'passenger@example.com',
          code: '123456',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      bloc.add(const VerifyOtpTimerTicked(secondsRemaining: 1));
      bloc.add(const VerifyOtpTimerTicked(secondsRemaining: 0));
    },
    expect: () => [
      const VerifyOtpTimerTicking(2),
      const VerifyOtpLoading(secondsRemaining: 2),
      const VerifyOtpFailure(
        'Invalid verification code. Try again.',
        secondsRemaining: 2,
      ),
      const VerifyOtpFailure(
        'Invalid verification code. Try again.',
        secondsRemaining: 1,
      ),
      const VerifyOtpFailure('Invalid verification code. Try again.'),
    ],
    verify: (bloc) {
      expect(bloc.state.canResend, isTrue);
      expect(bloc.state.secondsRemaining, 0);
    },
  );
}
