import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/features/auth/presentation/bloc/verify_otp/verify_otp_bloc.dart';
import 'package:passenger/src/features/auth/domain/repositories/passenger_auth_repository.dart';
import 'package:foundation/foundation.dart';

class MockPassengerAuthRepository extends Mock
    implements PassengerAuthRepository {}

void main() {
  late MockPassengerAuthRepository authRepository;

  setUp(() {
    authRepository = MockPassengerAuthRepository();
  });

  blocTest<VerifyOtpBloc, VerifyOtpState>(
    'requests a new code and restarts the cooldown after a successful resend',
    build: () {
      when(
        () => authRepository.requestVerificationCode(
          email: 'passenger@example.com',
        ),
      ).thenAnswer((_) async => const Right(null));
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
    'keeps resend available when the delivery request fails',
    build: () {
      when(
        () =>
            authRepository.requestVerificationCode(email: any(named: 'email')),
      ).thenAnswer(
        (_) async => const Left(ServerFailure('Mail service unavailable.')),
      );
      return VerifyOtpBloc(authRepository);
    },
    act: (bloc) => bloc.add(
      const VerifyOtpResendRequested(email: 'passenger@example.com'),
    ),
    expect: () => [
      isA<VerifyOtpResending>(),
      isA<VerifyOtpResendFailure>().having(
        (state) => state.errorMessage,
        'error message',
        "We couldn't send a new code right now. Please try again.",
      ),
    ],
  );
}
