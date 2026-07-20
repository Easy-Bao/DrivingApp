import 'package:equatable/equatable.dart';
import 'package:passenger_app/src/features/auth/domain/entities/auth_credentials.dart';

abstract class SignInState extends Equatable {
  const SignInState();

  @override
  List<Object?> get props => [];
}

class SignInInitial extends SignInState {
  const SignInInitial();
}

class SignInLoading extends SignInState {
  const SignInLoading();
}

class SignInSuccess extends SignInState {
  final AuthCredentials credentials;

  const SignInSuccess(this.credentials);

  @override
  List<Object?> get props => [credentials];
}

class SignInNeedsVerification extends SignInState {
  final String email;

  const SignInNeedsVerification(this.email);

  @override
  List<Object?> get props => [email];
}

class SignInFailure extends SignInState {
  final String errorMessage;

  const SignInFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
