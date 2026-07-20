import 'package:driver_app/src/features/auth/domain/usecases/reset_password_use_case.dart';
import 'package:driver_app/src/features/auth/presentation/cubits/forgot_password_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  final ResetPasswordUseCase _resetPasswordUseCase;

  ForgotPasswordCubit(this._resetPasswordUseCase) : super(const ForgotPasswordInitial());

  Future<void> sendResetLink(String email) async {
    final normalizedEmail = email.trim();
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
