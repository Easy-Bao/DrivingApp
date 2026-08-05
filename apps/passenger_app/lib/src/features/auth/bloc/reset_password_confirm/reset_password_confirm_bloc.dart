import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/features/auth/domain/usecases/confirm_reset_password_use_case.dart';
import 'package:passenger_app/src/features/auth/view/validation/auth_failure_message.dart';
import 'package:passenger_app/src/features/auth/view/validation/auth_form_validator.dart';

part 'reset_password_confirm_event.dart';
part 'reset_password_confirm_state.dart';

class ResetPasswordConfirmBloc
    extends Bloc<ResetPasswordConfirmEvent, ResetPasswordConfirmState> {
  final ConfirmResetPasswordUseCase _confirmResetPasswordUseCase;

  ResetPasswordConfirmBloc(this._confirmResetPasswordUseCase)
    : super(const ResetPasswordConfirmInitial()) {
    on<ResetPasswordConfirmSubmitted>(_onResetPasswordConfirmSubmitted);
  }

  Future<void> _onResetPasswordConfirmSubmitted(
    ResetPasswordConfirmSubmitted event,
    Emitter<ResetPasswordConfirmState> emit,
  ) async {
    final trimmedPassword = event.newPassword;
    final normalizedEmail = event.email.trim().toLowerCase();
    final validationError = authFormValidator.password(trimmedPassword);
    if (validationError != null) {
      emit(ResetPasswordConfirmFailure(validationError));
      return;
    }

    emit(const ResetPasswordConfirmLoading());

    final result = await _confirmResetPasswordUseCase.execute(
      email: normalizedEmail,
      code: event.code,
      newPassword: trimmedPassword,
    );

    result.fold(
      (failure) =>
          emit(ResetPasswordConfirmFailure(safeAuthFailureMessage(failure))),
      (_) => emit(const ResetPasswordConfirmSuccess()),
    );
  }
}
