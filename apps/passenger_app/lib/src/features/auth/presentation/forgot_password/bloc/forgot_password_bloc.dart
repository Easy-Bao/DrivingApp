import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/features/auth/domain/usecases/reset_password_use_case.dart';
import 'package:passenger_app/src/features/auth/presentation/forgot_password/bloc/forgot_password_event.dart';
import 'package:passenger_app/src/features/auth/presentation/forgot_password/bloc/forgot_password_state.dart';

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
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      emit(const ForgotPasswordFailure('Please enter a valid email address.'));
      return;
    }

    emit(const ForgotPasswordLoading());

    final result = await _resetPasswordUseCase.execute(email: normalizedEmail);

    result.fold(
      (failure) => emit(ForgotPasswordFailure(failure.message)),
      (_) => emit(const ForgotPasswordSuccess()),
    );
  }
}
