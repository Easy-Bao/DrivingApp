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
  final PassengerAuthCredentials credentials;

  const SignInSuccess(this.credentials);

  @override
  List<Object?> get props => [credentials];
}

final class SignInNeedsVerification extends SignInState {
  final String email;

  const SignInNeedsVerification(this.email);

  @override
  List<Object?> get props => [email];
}

final class SignInFailure extends SignInState {
  final String errorMessage;

  const SignInFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
