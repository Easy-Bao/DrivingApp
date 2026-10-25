import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:driver/src/features/auth/domain/repositories/driver_auth_repository.dart';
import 'package:driver/src/features/auth/presentation/bloc/reset_password/reset_password_event.dart';
import 'package:driver/src/features/auth/presentation/bloc/reset_password/reset_password_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foundation/foundation.dart';

export 'reset_password_event.dart';
export 'reset_password_state.dart';

class ResetPasswordBloc(this._authRepository)
    extends Bloc<ResetPasswordEvent, ResetPasswordState> {
  static const int minimumPasswordLength = 8;

  final AuthRepository _authRepository;

  this : super(const ResetPasswordInitial()) {
    on<ResetPasswordCodeRequested>(_onCodeRequested, transformer: droppable());
    on<ResetPasswordSubmitted>(
      _onResetPasswordSubmitted,
      transformer: droppable(),
    );
  }

  Future<void> _onCodeRequested(
    ResetPasswordCodeRequested event,
    Emitter<ResetPasswordState> emit,
  ) async {
    if (state is ResetPasswordLoading || state is ResetPasswordResending) {
      return;
    }
    emit(const ResetPasswordResending());
    final result = await _authRepository.resetPassword(
      email: event.email.trim().toLowerCase(),
    );
    result.fold(
      (failure) =>
          emit(ResetPasswordFailure(ErrorHandler.getErrorMessage(failure))),
      (_) => emit(const ResetPasswordCodeSent()),
    );
  }

  Future<void> _onResetPasswordSubmitted(
    ResetPasswordSubmitted event,
    Emitter<ResetPasswordState> emit,
  ) async {
    if (state is ResetPasswordLoading || state is ResetPasswordResending) {
      return;
    }
    final email = event.email.trim().toLowerCase();
    final code = event.code.trim();
    if (email.isEmpty || code.isEmpty) {
      emit(const ResetPasswordFailure('Enter the verification code.'));
      return;
    }
    if (event.newPassword.length < minimumPasswordLength) {
      emit(
        const ResetPasswordFailure(
          'Password must be at least $minimumPasswordLength characters.',
        ),
      );
      return;
    }

    emit(const ResetPasswordLoading());

    final result = await _authRepository.confirmPasswordReset(
      email: email,
      code: code,
      newPassword: event.newPassword,
    );

    result.fold(
      (failure) =>
          emit(ResetPasswordFailure(ErrorHandler.getErrorMessage(failure))),
      (_) => emit(const ResetPasswordSuccess()),
    );
  }
}
