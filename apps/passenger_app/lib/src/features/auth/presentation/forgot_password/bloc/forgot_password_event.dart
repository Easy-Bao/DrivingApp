import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/forgot_password_event.freezed.dart';

@freezed
sealed class ForgotPasswordEvent with _$ForgotPasswordEvent {
  const factory ForgotPasswordEvent.submitted({
    required String email,
  }) = ForgotPasswordSubmitted;
}
