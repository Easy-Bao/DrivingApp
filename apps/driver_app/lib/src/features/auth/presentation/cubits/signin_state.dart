import 'package:driver_app/src/features/auth/domain/entities/auth_credentials.dart';
import 'package:equatable/equatable.dart';

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

class SignInFailure extends SignInState {
  final String errorMessage;

  const SignInFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
