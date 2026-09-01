import 'package:equatable/equatable.dart';

sealed class ForgotPasswordState extends Equatable {
  const ForgotPasswordState();

  @override
  List<Object?> get props => [];
}

final class const ForgotPasswordInitial() extends ForgotPasswordState;

final class const ForgotPasswordLoading() extends ForgotPasswordState;

final class const ForgotPasswordSuccess() extends ForgotPasswordState;

final class const ForgotPasswordFailure(final String errorMessage)
    extends ForgotPasswordState {
  @override
  List<Object?> get props => [errorMessage];
}
