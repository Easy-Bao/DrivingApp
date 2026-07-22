import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthLoggedIn extends AuthEvent {
  final String token;
  final String userId;

  const AuthLoggedIn({required this.token, required this.userId});

  @override
  List<Object?> get props => [token, userId];
}

class AuthLoggedOut extends AuthEvent {
  const AuthLoggedOut();
}
