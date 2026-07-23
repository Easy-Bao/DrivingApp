import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/features/auth/domain/usecases/confirm_reset_password_use_case.dart';
import 'package:passenger_app/src/features/auth/presentation/cubits/reset_password_confirm_state.dart';

class ResetPasswordConfirmCubit extends Cubit<ResetPasswordConfirmState> {
  final ConfirmResetPasswordUseCase _confirmResetPasswordUseCase;

  ResetPasswordConfirmCubit(this._confirmResetPasswordUseCase)
      : super(const ResetPasswordConfirmInitial());

  Future<void> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final trimmedPassword = newPassword.trim();
    if (trimmedPassword.length < 8) {
      emit(const ResetPasswordConfirmFailure(
        'Password must be at least 8 characters.',
      ));
      return;
    }

    emit(const ResetPasswordConfirmLoading());

    final result = await _confirmResetPasswordUseCase.execute(
      email: email,
      code: code,
      newPassword: trimmedPassword,
    );

    result.fold(
      (failure) => emit(ResetPasswordConfirmFailure(failure.message)),
      (_) => emit(const ResetPasswordConfirmSuccess()),
    );
  }
}
