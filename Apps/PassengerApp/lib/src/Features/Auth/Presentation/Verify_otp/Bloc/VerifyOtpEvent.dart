import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/verify_otp_event.freezed.dart';

@freezed
sealed class VerifyOtpEvent with _$VerifyOtpEvent {
  const factory VerifyOtpEvent.timerStarted() = VerifyOtpTimerStarted;
  const factory VerifyOtpEvent.timerTicked({
    required int secondsRemaining,
  }) = VerifyOtpTimerTicked;
  const factory VerifyOtpEvent.submitted({
    required String email,
    required String code,
    @Default('') String password,
  }) = VerifyOtpSubmitted;
}
