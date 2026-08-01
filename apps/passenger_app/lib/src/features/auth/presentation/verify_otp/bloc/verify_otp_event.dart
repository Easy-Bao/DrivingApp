import 'package:equatable/equatable.dart';

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
  final String password;

  const VerifyOtpSubmitted({
    required this.email,
    required this.code,
    this.password = '',
  });

  @override
  List<Object?> get props => [email, code, password];
}
