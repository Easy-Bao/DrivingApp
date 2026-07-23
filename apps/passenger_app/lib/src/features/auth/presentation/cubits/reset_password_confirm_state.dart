import 'package:equatable/equatable.dart';

abstract class ResetPasswordConfirmState extends Equatable {
  const ResetPasswordConfirmState();

  @override
  List<Object?> get props => [];
}

class ResetPasswordConfirmInitial extends ResetPasswordConfirmState {
  const ResetPasswordConfirmInitial();
}

class ResetPasswordConfirmLoading extends ResetPasswordConfirmState {
  const ResetPasswordConfirmLoading();
}

class ResetPasswordConfirmSuccess extends ResetPasswordConfirmState {
  const ResetPasswordConfirmSuccess();
}

class ResetPasswordConfirmFailure extends ResetPasswordConfirmState {
  final String errorMessage;

  const ResetPasswordConfirmFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
