part of 'sign_up_bloc.dart';

sealed class SignUpState extends Equatable {
  const SignUpState();

  @override
  List<Object?> get props => [];
}

class SignUpInitial extends SignUpState {
  const SignUpInitial();
}

class SignUpLoading extends SignUpState {
  const SignUpLoading();
}

class SignUpNeedsVerification extends SignUpState {
  final String email;

  const SignUpNeedsVerification(this.email);

  @override
  List<Object?> get props => [email];
}

class SignUpSuccess extends SignUpState {
  final AuthCredentials credentials;

  const SignUpSuccess(this.credentials);

  @override
  List<Object?> get props => [credentials];
}

class SignUpFailure extends SignUpState {
  final String errorMessage;

  const SignUpFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
