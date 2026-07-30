import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/reset_password_confirm_event.freezed.dart';

@freezed
sealed class ResetPasswordConfirmEvent with _$ResetPasswordConfirmEvent {
  const factory ResetPasswordConfirmEvent.submitted({
    required String email,
    required String code,
    required String newPassword,
  }) = ResetPasswordConfirmSubmitted;
}
