import 'package:driver_app/src/features/auth/domain/usecases/reset_password_use_case.dart';
import 'package:driver_app/src/features/auth/presentation/forgot_password/bloc/forgot_password_event.dart';
import 'package:driver_app/src/features/auth/presentation/forgot_password/bloc/forgot_password_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'package:driver_app/src/features/auth/presentation/forgot_password/bloc/forgot_password_event.dart';
export 'package:driver_app/src/features/auth/presentation/forgot_password/bloc/forgot_password_state.dart';

class ForgotPasswordBloc
    extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  final ResetPasswordUseCase _resetPasswordUseCase;

  ForgotPasswordBloc(this._resetPasswordUseCase)
      : super(const ForgotPasswordState.initial()) {
    on<ForgotPasswordSubmitted>(_onForgotPasswordSubmitted);
  }

  Future<void> _onForgotPasswordSubmitted(
    ForgotPasswordSubmitted event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    final normalizedEmail = event.email.trim();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      emit(
        const ForgotPasswordState.failure(
          'Please enter a valid email address.',
        ),
      );
      return;
    }

    emit(const ForgotPasswordState.loading());

    final result = await _resetPasswordUseCase.execute(email: normalizedEmail);

    result.fold(
      (failure) => emit(ForgotPasswordState.failure(failure.message)),
      (_) => emit(const ForgotPasswordState.success()),
    );
  }
}
