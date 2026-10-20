import 'package:equatable/equatable.dart';

sealed class const ResetPasswordState() extends Equatable {
  @override
  List<Object?> get props => [];
}

final class const ResetPasswordInitial() extends ResetPasswordState;

final class const ResetPasswordLoading() extends ResetPasswordState;

final class const ResetPasswordSuccess() extends ResetPasswordState;

final class const ResetPasswordFailure(final String errorMessage)
    extends ResetPasswordState {
  @override
  List<Object?> get props => [errorMessage];
}
