import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:passenger/src/features/auth/presentation/validation/auth_failure_message.dart';
import 'package:passenger/src/features/auth/presentation/validation/auth_form_validator.dart';

part 'reset_password_confirm_event.dart';
part 'reset_password_confirm_state.dart';

class ResetPasswordConfirmBloc(this._authRepository)
    extends Bloc<ResetPasswordConfirmEvent, ResetPasswordConfirmState> {
  final AuthRepository _authRepository;

  this : super(const ResetPasswordConfirmInitial()) {
    on<ResetPasswordCodeRequested>(_onCodeRequested, transformer: droppable());
    on<ResetPasswordConfirmSubmitted>(
      _onResetPasswordConfirmSubmitted,
      transformer: droppable(),
    );
  }

  Future<void> _onCodeRequested(
    ResetPasswordCodeRequested event,
    Emitter<ResetPasswordConfirmState> emit,
  ) async {
    if (state is ResetPasswordConfirmLoading ||
        state is ResetPasswordCodeResending) {
      return;
    }
    emit(const ResetPasswordCodeResending());
    final result = await _authRepository.resetPassword(
      email: event.email.trim().toLowerCase(),
    );
    result.fold(
      (failure) =>
          emit(ResetPasswordConfirmFailure(safeAuthFailureMessage(failure))),
      (_) => emit(const ResetPasswordCodeSent()),
    );
  }

  Future<void> _onResetPasswordConfirmSubmitted(
    ResetPasswordConfirmSubmitted event,
    Emitter<ResetPasswordConfirmState> emit,
  ) async {
    if (state is ResetPasswordConfirmLoading ||
        state is ResetPasswordCodeResending) {
      return;
    }
    final trimmedPassword = event.newPassword;
    final normalizedEmail = event.email.trim().toLowerCase();
    final validationError = authFormValidator.password(trimmedPassword);
    if (validationError != null) {
      emit(ResetPasswordConfirmFailure(validationError));
      return;
    }

    emit(const ResetPasswordConfirmLoading());

    final result = await _authRepository.confirmResetPassword(
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
