import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/features/auth/presentation/bloc/verify_otp/verify_otp_bloc.dart';
import 'package:passenger_app/src/features/auth/domain/use_cases/resend_otp_use_case.dart';
import 'package:passenger_app/src/features/auth/domain/use_cases/verify_otp_use_case.dart';
import 'package:shared_core/shared_core.dart';

class MockVerifyOtpUseCase extends Mock implements VerifyOtpUseCase {}

class MockResendOtpUseCase extends Mock implements ResendOtpUseCase {}

void main() {
  late MockVerifyOtpUseCase verifyOtpUseCase;
  late MockResendOtpUseCase resendOtpUseCase;

  setUp(() {
    verifyOtpUseCase = MockVerifyOtpUseCase();
    resendOtpUseCase = MockResendOtpUseCase();
  });

  blocTest<VerifyOtpBloc, VerifyOtpState>(
    'requests a new code and restarts the cooldown after a successful resend',
    build: () {
      when(
        () => resendOtpUseCase.execute(email: 'passenger@example.com'),
      ).thenAnswer((_) async => const Right(null));
      return VerifyOtpBloc(verifyOtpUseCase, resendOtpUseCase);
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
        () => resendOtpUseCase.execute(email: 'passenger@example.com'),
      ).called(1);
    },
  );

  blocTest<VerifyOtpBloc, VerifyOtpState>(
    'keeps resend available when the delivery request fails',
    build: () {
      when(
        () => resendOtpUseCase.execute(email: any(named: 'email')),
      ).thenAnswer(
        (_) async => const Left(ServerFailure('Mail service unavailable.')),
      );
      return VerifyOtpBloc(verifyOtpUseCase, resendOtpUseCase);
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
