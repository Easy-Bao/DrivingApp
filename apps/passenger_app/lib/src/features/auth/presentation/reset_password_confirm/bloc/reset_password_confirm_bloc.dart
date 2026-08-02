import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/features/auth/domain/usecases/confirm_reset_password_use_case.dart';
import 'package:passenger_app/src/features/auth/presentation/reset_password_confirm/bloc/reset_password_confirm_event.dart';
import 'package:passenger_app/src/features/auth/presentation/reset_password_confirm/bloc/reset_password_confirm_state.dart';

export 'package:passenger_app/src/features/auth/presentation/reset_password_confirm/bloc/reset_password_confirm_event.dart';
export 'package:passenger_app/src/features/auth/presentation/reset_password_confirm/bloc/reset_password_confirm_state.dart';

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
    final trimmedPassword = event.newPassword.trim();
    final normalizedEmail = event.email.trim().toLowerCase();
    if (trimmedPassword.length < 8) {
      emit(
        const ResetPasswordConfirmFailure(
          'Password must be at least 8 characters.',
        ),
      );
      return;
    }

    emit(const ResetPasswordConfirmLoading());

    final result = await _confirmResetPasswordUseCase.execute(
      email: normalizedEmail,
      code: event.code,
      newPassword: trimmedPassword,
    );

    result.fold(
      (failure) => emit(ResetPasswordConfirmFailure(failure.message)),
      (_) => emit(const ResetPasswordConfirmSuccess()),
    );
  }
}
