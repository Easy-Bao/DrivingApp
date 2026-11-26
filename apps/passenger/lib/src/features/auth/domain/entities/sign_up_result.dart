import 'package:equatable/equatable.dart';
import 'package:passenger/src/features/auth/domain/entities/auth_credentials.dart';

sealed class SignUpResult extends Equatable {
  const SignUpResult();
}

final class SignUpVerificationRequired extends SignUpResult {
  const SignUpVerificationRequired({required this.email});

  final String email;

  @override
  List<Object?> get props => [email];
}

final class SignUpAuthenticated extends SignUpResult {
  const SignUpAuthenticated(this.credentials);

  final AuthCredentials credentials;

  @override
  List<Object?> get props => [credentials];
}
