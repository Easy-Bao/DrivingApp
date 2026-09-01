import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger/src/features/auth/domain/repositories/passenger_auth_repository.dart';
import 'package:passenger/src/features/auth/presentation/validation/auth_failure_message.dart';
import 'package:passenger/src/features/auth/presentation/validation/auth_form_validator.dart';

part 'reset_password_confirm_event.dart';
part 'reset_password_confirm_state.dart';

class ResetPasswordConfirmBloc(this._authRepository)
    extends Bloc<ResetPasswordConfirmEvent, ResetPasswordConfirmState> {
  final PassengerAuthRepository _authRepository;

  this : super(const ResetPasswordConfirmInitial()) {
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
