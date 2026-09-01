import 'package:equatable/equatable.dart';

sealed class const ForgotPasswordState() extends Equatable {
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
