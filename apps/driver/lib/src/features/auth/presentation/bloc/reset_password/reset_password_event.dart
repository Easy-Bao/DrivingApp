import 'package:equatable/equatable.dart';

sealed class const ResetPasswordEvent() extends Equatable {
  @override
  List<Object?> get props => [];
}

final class const ResetPasswordSubmitted({
  required this.email,
  required this.code,
  required this.newPassword,
}) extends ResetPasswordEvent {
  final String email;
  final String code;
  final String newPassword;

  @override
  List<Object?> get props => [email, code, newPassword];
}
