import 'package:driver_app/src/features/auth/domain/use_cases/reset_password_use_case.dart';
import 'package:driver_app/src/features/auth/presentation/bloc/forgot_password/forgot_password_event.dart';
import 'package:driver_app/src/features/auth/presentation/bloc/forgot_password/forgot_password_state.dart';
import 'package:foundation/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'forgot_password_event.dart';
export 'forgot_password_state.dart';

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
    final normalizedEmail = event.email.trim();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      emit(const ForgotPasswordFailure('Please enter a valid email address.'));
      return;
    }

    emit(const ForgotPasswordLoading());

    final result = await _resetPasswordUseCase.execute(email: normalizedEmail);

    result.fold(
      (failure) =>
          emit(ForgotPasswordFailure(ErrorHandler.getErrorMessage(failure))),
      (_) => emit(const ForgotPasswordSuccess()),
    );
  }
}
