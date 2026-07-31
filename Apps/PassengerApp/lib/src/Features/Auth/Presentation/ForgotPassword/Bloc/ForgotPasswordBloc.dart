import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/Features/Auth/Domain/Usecases/ResetPasswordUseCase.dart';
import 'package:passenger_app/src/Features/Auth/Presentation/ForgotPassword/Bloc/ForgotPasswordEvent.dart';
import 'package:passenger_app/src/Features/Auth/Presentation/ForgotPassword/Bloc/ForgotPasswordState.dart';

export 'package:passenger_app/src/features/auth/presentation/forgot_password/bloc/forgot_password_event.dart';
export 'package:passenger_app/src/features/auth/presentation/forgot_password/bloc/forgot_password_state.dart';

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
    final normalizedEmail = event.email.trim().toLowerCase();
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
