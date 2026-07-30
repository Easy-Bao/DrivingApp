import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/verify_otp_state.freezed.dart';

@freezed
sealed class VerifyOtpState with _$VerifyOtpState {
  const factory VerifyOtpState.initial() = VerifyOtpInitial;
  const factory VerifyOtpState.timerTicking(int secondsRemaining) =
      VerifyOtpTimerTicking;
  const factory VerifyOtpState.timerExpired() = VerifyOtpTimerExpired;
  const factory VerifyOtpState.loading() = VerifyOtpLoading;
  const factory VerifyOtpState.success() = VerifyOtpSuccess;
  const factory VerifyOtpState.failure(String errorMessage) = VerifyOtpFailure;
}
