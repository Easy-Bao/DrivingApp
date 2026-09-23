part of 'verify_otp_bloc.dart';

sealed class const VerifyOtpEvent() extends Equatable {
  @override
  List<Object?> get props => [];
}

final class const VerifyOtpTimerStarted() extends VerifyOtpEvent {}

final class const VerifyOtpTimerTicked({required this.secondsRemaining})
    extends VerifyOtpEvent {
  final int secondsRemaining;

  @override
  List<Object?> get props => [secondsRemaining];
}

final class const VerifyOtpSubmitted({required this.email, required this.code})
    extends VerifyOtpEvent {
  final String email;
  final String code;

  @override
  List<Object?> get props => [email, code];
}

final class const VerifyOtpResendRequested({required this.email})
    extends VerifyOtpEvent {
  final String email;

  @override
  List<Object?> get props => [email];
}
