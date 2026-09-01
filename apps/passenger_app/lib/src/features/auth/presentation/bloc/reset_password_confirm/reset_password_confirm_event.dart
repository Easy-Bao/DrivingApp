part of 'reset_password_confirm_bloc.dart';

sealed class const ResetPasswordConfirmEvent() extends Equatable {
  @override
  List<Object?> get props => [];
}

class const ResetPasswordConfirmSubmitted({
  required this.email,
  required this.code,
  required this.newPassword,
}) extends ResetPasswordConfirmEvent {
  final String email;
  final String code;
  final String newPassword;

  @override
  List<Object?> get props => [email, code, newPassword];
}
