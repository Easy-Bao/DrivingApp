import 'package:driver_app/src/features/auth/domain/entities/auth_credentials.dart';
import 'package:equatable/equatable.dart';

abstract class SignUpState extends Equatable {
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

class SignUpSuccess extends SignUpState {
  final AuthCredentials credentials;
  const SignUpSuccess(this.credentials);

  @override
  List<Object?> get props => [credentials];
}

class SignUpNeedsVerification extends SignUpState {
  final String email;
  const SignUpNeedsVerification(this.email);

  @override
  List<Object?> get props => [email];
}

class SignUpFailure extends SignUpState {
  final String message;
  const SignUpFailure(this.message);

  @override
  List<Object?> get props => [message];
}
