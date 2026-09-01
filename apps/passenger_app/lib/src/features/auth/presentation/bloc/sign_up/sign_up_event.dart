part of 'sign_up_bloc.dart';

sealed class const SignUpEvent() extends Equatable {
  @override
  List<Object?> get props => [];
}

class const SignUpSubmitted({
  required this.name,
  required this.email,
  required this.phone,
  required this.password,
}) extends SignUpEvent {
  final String name;
  final String email;
  final String phone;
  final String password;

  @override
  List<Object?> get props => [name, email, phone, password];
}
