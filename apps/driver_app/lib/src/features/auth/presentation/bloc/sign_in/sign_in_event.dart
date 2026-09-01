import 'package:equatable/equatable.dart';

sealed class const SignInEvent() extends Equatable {
  @override
  List<Object?> get props => [];
}

final class const SignInSubmitted({required this.email, required this.password})
    extends SignInEvent {
  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}
