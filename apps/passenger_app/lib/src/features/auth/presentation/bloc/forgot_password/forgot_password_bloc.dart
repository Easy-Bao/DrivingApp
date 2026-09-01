import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/features/auth/domain/repositories/passenger_auth_repository.dart';
import 'package:passenger_app/src/features/auth/presentation/bloc/forgot_password/forgot_password_event.dart';
import 'package:passenger_app/src/features/auth/presentation/bloc/forgot_password/forgot_password_state.dart';
import 'package:passenger_app/src/features/auth/presentation/validation/auth_failure_message.dart';
import 'package:passenger_app/src/features/auth/presentation/validation/auth_form_validator.dart';

export 'forgot_password_event.dart';
export 'forgot_password_state.dart';

class ForgotPasswordBloc(this._authRepository)
    extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  final PassengerAuthRepository _authRepository;

  this : super(const ForgotPasswordInitial()) {
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

    final result = await _authRepository.resetPassword(email: normalizedEmail);

    result.fold(
      (failure) => emit(ForgotPasswordFailure(safeAuthFailureMessage(failure))),
      (_) => emit(const ForgotPasswordSuccess()),
    );
  }
}
