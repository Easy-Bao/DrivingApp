import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/features/auth/domain/usecases/reset_password_use_case.dart';
import 'package:passenger_app/src/features/auth/presentation/forgot_password/bloc/forgot_password_event.dart';
import 'package:passenger_app/src/features/auth/presentation/forgot_password/bloc/forgot_password_state.dart';
import 'package:passenger_app/src/features/auth/presentation/validation/auth_failure_message.dart';
import 'package:passenger_app/src/features/auth/presentation/validation/auth_form_validator.dart';

export 'package:passenger_app/src/features/auth/presentation/forgot_password/bloc/forgot_password_event.dart';
export 'package:passenger_app/src/features/auth/presentation/forgot_password/bloc/forgot_password_state.dart';

class ForgotPasswordBloc
    extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  final ResetPasswordUseCase _resetPasswordUseCase;

  ForgotPasswordBloc(this._resetPasswordUseCase)
    : super(const ForgotPasswordInitial()) {
    on<ForgotPasswordSubmitted>(_onForgotPasswordSubmitted);
  }

  Future<void> _onForgotPasswordSubmitted(
    ForgotPasswordSubmitted event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    final normalizedEmail = event.email.trim().toLowerCase();
    final validationError = authFormValidator.email(normalizedEmail);
    if (validationError != null) {
      emit(ForgotPasswordFailure(validationError));
      return;
    }

    emit(const ForgotPasswordLoading());

    final result = await _resetPasswordUseCase.execute(email: normalizedEmail);

    result.fold(
      (failure) => emit(ForgotPasswordFailure(safeAuthFailureMessage(failure))),
      (_) => emit(const ForgotPasswordSuccess()),
    );
  }
}
