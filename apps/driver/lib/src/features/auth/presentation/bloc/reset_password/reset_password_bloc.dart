import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:driver/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:driver/src/features/auth/presentation/bloc/reset_password/reset_password_event.dart';
import 'package:driver/src/features/auth/presentation/bloc/reset_password/reset_password_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foundation/foundation.dart';

export 'reset_password_event.dart';
export 'reset_password_state.dart';

class ResetPasswordBloc(this._authRepository)
    extends Bloc<ResetPasswordEvent, ResetPasswordState> {
  static const int minimumPasswordLength = 8;
  static final RegExp _otpPattern = RegExp(r'^\d{6}$');

  final AuthRepository _authRepository;
  String? _verifiedCode;

  this : super(const ResetPasswordInitial()) {
    on<ResetPasswordCodeRequested>(_onCodeRequested, transformer: droppable());
    on<ResetPasswordCodeVerifyRequested>(
      _onVerifyCodeRequested,
      transformer: droppable(),
    );
    on<ResetPasswordCodeVerificationReset>((_, emit) {
      _verifiedCode = null;
      if (state is ResetPasswordCodeVerificationFailure ||
          state is ResetPasswordResendFailure ||
          state is ResetPasswordFailure ||
          state is ResetPasswordCodeVerified) {
        emit(const ResetPasswordInitial());
      }
    });
    on<ResetPasswordSubmitted>(
      _onResetPasswordSubmitted,
      transformer: droppable(),
    );
  }

  Future<void> _onCodeRequested(
    ResetPasswordCodeRequested event,
    Emitter<ResetPasswordState> emit,
  ) async {
    if (state is ResetPasswordLoading ||
        state is ResetPasswordCodeVerifying ||
        state is ResetPasswordResending) {
      return;
    }
    _verifiedCode = null;
    emit(const ResetPasswordResending());
    final result = await _authRepository.resetPassword(
      email: event.email.trim().toLowerCase(),
    );
    result.fold(
      (failure) => emit(
        ResetPasswordResendFailure(ErrorHandler.getErrorMessage(failure)),
      ),
      (_) => emit(const ResetPasswordCodeSent()),
    );
  }

  Future<void> _onVerifyCodeRequested(
    ResetPasswordCodeVerifyRequested event,
    Emitter<ResetPasswordState> emit,
  ) async {
    if (state is ResetPasswordLoading ||
        state is ResetPasswordCodeVerifying ||
        state is ResetPasswordResending) {
      return;
    }
    final email = event.email.trim().toLowerCase();
    final code = event.code.trim();
    if (email.isEmpty || !_otpPattern.hasMatch(code)) {
      emit(
        const ResetPasswordCodeVerificationFailure(
          'Enter the 6-digit verification code.',
        ),
      );
      return;
    }
    if (_verifiedCode == code) {
      emit(const ResetPasswordCodeVerified());
      return;
    }
    emit(const ResetPasswordCodeVerifying());
    final result = await _authRepository.verifyResetOtp(
      email: email,
      code: code,
    );
    result.fold(
      (failure) => emit(
        ResetPasswordCodeVerificationFailure(
          ErrorHandler.getErrorMessage(failure),
        ),
      ),
      (_) {
        _verifiedCode = code;
        emit(const ResetPasswordCodeVerified());
      },
    );
  }

  Future<void> _onResetPasswordSubmitted(
    ResetPasswordSubmitted event,
    Emitter<ResetPasswordState> emit,
  ) async {
    if (state is ResetPasswordLoading ||
        state is ResetPasswordCodeVerifying ||
        state is ResetPasswordResending) {
      return;
    }
    final email = event.email.trim().toLowerCase();
    final code = event.code.trim();
    if (email.isEmpty || !_otpPattern.hasMatch(code)) {
      emit(const ResetPasswordFailure('Enter the 6-digit verification code.'));
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
