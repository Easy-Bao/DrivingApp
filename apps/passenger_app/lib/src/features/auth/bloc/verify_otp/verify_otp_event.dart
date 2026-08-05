part of 'verify_otp_bloc.dart';

sealed class VerifyOtpEvent extends Equatable {
  const VerifyOtpEvent();

  @override
  List<Object?> get props => [];
}

class VerifyOtpTimerStarted extends VerifyOtpEvent {
  const VerifyOtpTimerStarted();
}

class VerifyOtpTimerTicked extends VerifyOtpEvent {
  final int secondsRemaining;

  const VerifyOtpTimerTicked({required this.secondsRemaining});

  @override
  List<Object?> get props => [secondsRemaining];
}

class VerifyOtpSubmitted extends VerifyOtpEvent {
  final String email;
  final String code;

  const VerifyOtpSubmitted({required this.email, required this.code});

  @override
  List<Object?> get props => [email, code];
}

class VerifyOtpResendRequested extends VerifyOtpEvent {
  final String email;

  const VerifyOtpResendRequested({required this.email});

  @override
  List<Object?> get props => [email];
}
