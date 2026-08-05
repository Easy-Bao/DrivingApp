part of 'reset_password_confirm_bloc.dart';

sealed class ResetPasswordConfirmEvent extends Equatable {
  const ResetPasswordConfirmEvent();

  @override
  List<Object?> get props => [];
}

class ResetPasswordConfirmSubmitted extends ResetPasswordConfirmEvent {
  final String email;
  final String code;
  final String newPassword;

  const ResetPasswordConfirmSubmitted({
    required this.email,
    required this.code,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [email, code, newPassword];
}
