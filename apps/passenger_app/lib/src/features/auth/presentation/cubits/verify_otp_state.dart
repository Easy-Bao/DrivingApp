import 'package:equatable/equatable.dart';

abstract class VerifyOtpState extends Equatable {
  const VerifyOtpState();

  @override
  List<Object?> get props => [];
}

class VerifyOtpInitial extends VerifyOtpState {
  const VerifyOtpInitial();
}

class VerifyOtpTimerTicking extends VerifyOtpState {
  final int secondsRemaining;

  const VerifyOtpTimerTicking(this.secondsRemaining);

  @override
  List<Object?> get props => [secondsRemaining];
}

class VerifyOtpTimerExpired extends VerifyOtpState {
  const VerifyOtpTimerExpired();
}

class VerifyOtpLoading extends VerifyOtpState {
  const VerifyOtpLoading();
}

class VerifyOtpSuccess extends VerifyOtpState {
  const VerifyOtpSuccess();
}

class VerifyOtpFailure extends VerifyOtpState {
  final String errorMessage;

  const VerifyOtpFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
