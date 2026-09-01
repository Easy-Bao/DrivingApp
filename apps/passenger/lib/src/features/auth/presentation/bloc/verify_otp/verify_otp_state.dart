part of 'verify_otp_bloc.dart';

sealed class const VerifyOtpState() extends Equatable {
  @override
  List<Object?> get props => [];
}

final class const VerifyOtpInitial() extends VerifyOtpState;

final class const VerifyOtpTimerTicking(final int secondsRemaining)
    extends VerifyOtpState {
  @override
  List<Object?> get props => [secondsRemaining];
}

final class const VerifyOtpTimerExpired() extends VerifyOtpState;

final class const VerifyOtpLoading() extends VerifyOtpState;

final class const VerifyOtpSuccess() extends VerifyOtpState;

final class const VerifyOtpFailure(final String errorMessage)
    extends VerifyOtpState {
  @override
  List<Object?> get props => [errorMessage];
}

final class const VerifyOtpResending() extends VerifyOtpState;

final class const VerifyOtpResent() extends VerifyOtpState;

final class const VerifyOtpResendFailure(final String errorMessage)
    extends VerifyOtpState {
  @override
  List<Object?> get props => [errorMessage];
}
