part of 'reset_password_confirm_bloc.dart';

sealed class const ResetPasswordConfirmState() extends Equatable {
  @override
  List<Object?> get props => [];
}

final class const ResetPasswordConfirmInitial()
    extends ResetPasswordConfirmState;

final class const ResetPasswordConfirmLoading()
    extends ResetPasswordConfirmState;

final class const ResetPasswordConfirmSuccess()
    extends ResetPasswordConfirmState;

final class const ResetPasswordConfirmFailure(final String errorMessage)
    extends ResetPasswordConfirmState {
  @override
  List<Object?> get props => [errorMessage];
}
