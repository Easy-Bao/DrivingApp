part of 'sign_in_bloc.dart';

sealed class SignInState extends Equatable {
  const SignInState();

  @override
  List<Object?> get props => [];
}

final class SignInInitial extends SignInState {
  const SignInInitial();
}

final class SignInLoading extends SignInState {
  const SignInLoading();
}

final class SignInSuccess extends SignInState {
  final DriverAuthCredentials credentials;

  const SignInSuccess(this.credentials);

  @override
  List<Object?> get props => [credentials];
}

final class SignInFailure extends SignInState {
  final String errorMessage;

  const SignInFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
