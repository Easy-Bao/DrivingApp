part of 'sign_up_bloc.dart';

sealed class const SignUpState() extends Equatable {
  @override
  List<Object?> get props => [];
}

final class const SignUpInitial() extends SignUpState;

final class const SignUpLoading() extends SignUpState;

final class const SignUpNeedsVerification(final String email)
    extends SignUpState {
  @override
  List<Object?> get props => [email];
}

final class const SignUpSuccess(final PassengerAuthCredentials credentials)
    extends SignUpState {
  @override
  List<Object?> get props => [credentials];
}

final class const SignUpFailure(final String errorMessage) extends SignUpState {
  @override
  List<Object?> get props => [errorMessage];
}
