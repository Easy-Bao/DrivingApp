import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class Authenticated extends AuthState {
  final String token;
  final String userId;

  const Authenticated({required this.token, required this.userId});

  @override
  List<Object?> get props => [token, userId];
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}
