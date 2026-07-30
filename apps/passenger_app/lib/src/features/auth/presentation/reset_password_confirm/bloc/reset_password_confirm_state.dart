import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/reset_password_confirm_state.freezed.dart';

@freezed
sealed class ResetPasswordConfirmState with _$ResetPasswordConfirmState {
  const factory ResetPasswordConfirmState.initial() =
      ResetPasswordConfirmInitial;
  const factory ResetPasswordConfirmState.loading() =
      ResetPasswordConfirmLoading;
  const factory ResetPasswordConfirmState.success() =
      ResetPasswordConfirmSuccess;
  const factory ResetPasswordConfirmState.failure(String errorMessage) =
      ResetPasswordConfirmFailure;
}
