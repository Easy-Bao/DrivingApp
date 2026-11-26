part of 'verify_otp_bloc.dart';

sealed class VerifyOtpState extends Equatable {
  const VerifyOtpState({required this.secondsRemaining});

  final int secondsRemaining;

  bool get canResend => secondsRemaining <= 0;

  @override
  List<Object?> get props => [secondsRemaining];
}

final class VerifyOtpInitial extends VerifyOtpState {
  const VerifyOtpInitial({super.secondsRemaining = 60});
}

final class VerifyOtpTimerTicking extends VerifyOtpState {
  const VerifyOtpTimerTicking(int secondsRemaining)
    : super(secondsRemaining: secondsRemaining);
}

final class VerifyOtpTimerExpired extends VerifyOtpState {
  const VerifyOtpTimerExpired() : super(secondsRemaining: 0);
}

final class VerifyOtpLoading extends VerifyOtpState {
  const VerifyOtpLoading({super.secondsRemaining = 0});
}

final class VerifyOtpSuccess extends VerifyOtpState {
  const VerifyOtpSuccess({super.secondsRemaining = 0});
}

final class VerifyOtpFailure extends VerifyOtpState {
  const VerifyOtpFailure(this.errorMessage, {super.secondsRemaining = 0});

  final String errorMessage;

  @override
  List<Object?> get props => [errorMessage, secondsRemaining];
}

final class VerifyOtpResending extends VerifyOtpState {
  const VerifyOtpResending({super.secondsRemaining = 0});
}

final class VerifyOtpResent extends VerifyOtpState {
  const VerifyOtpResent({super.secondsRemaining = 0});
}

final class VerifyOtpResendFailure extends VerifyOtpState {
  const VerifyOtpResendFailure(this.errorMessage, {super.secondsRemaining = 0});

  final String errorMessage;

  @override
  List<Object?> get props => [errorMessage, secondsRemaining];
}
