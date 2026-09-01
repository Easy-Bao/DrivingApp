part of 'sign_in_bloc.dart';

sealed class SignInState extends Equatable {
  const SignInState();

  @override
  List<Object?> get props => [];
}

final class const SignInInitial() extends SignInState;

final class const SignInLoading() extends SignInState;

final class const SignInSuccess(final PassengerAuthCredentials credentials)
    extends SignInState {
  @override
  List<Object?> get props => [credentials];
}

final class const SignInNeedsVerification(final String email)
    extends SignInState {
  @override
  List<Object?> get props => [email];
}

final class const SignInFailure(final String errorMessage) extends SignInState {
  @override
  List<Object?> get props => [errorMessage];
}
