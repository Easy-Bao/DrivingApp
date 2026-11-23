import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:passenger/src/features/auth/presentation/validation/auth_failure_message.dart';
import 'package:passenger/src/features/auth/presentation/validation/auth_form_validator.dart';

part 'reset_password_confirm_event.dart';
part 'reset_password_confirm_state.dart';

class ResetPasswordConfirmBloc(this._authRepository)
    extends Bloc<ResetPasswordConfirmEvent, ResetPasswordConfirmState> {
  static final RegExp _otpPattern = RegExp(r'^\d{6}$');

  final AuthRepository _authRepository;
  String? _verifiedCode;

  this : super(const ResetPasswordConfirmInitial()) {
    on<ResetPasswordCodeRequested>(_onCodeRequested, transformer: droppable());
    on<ResetPasswordCodeVerifyRequested>(
      _onVerifyCodeRequested,
      transformer: droppable(),
    );
    on<ResetPasswordCodeVerificationReset>((_, emit) {
      if (state is ResetPasswordCodeVerificationFailure ||
          state is ResetPasswordConfirmFailure ||
          state is ResetPasswordCodeVerified) {
        emit(const ResetPasswordConfirmInitial());
      }
    });
    on<ResetPasswordConfirmSubmitted>(
      _onResetPasswordConfirmSubmitted,
      transformer: droppable(),
    );
  }

  Future<void> _onCodeRequested(
    ResetPasswordCodeRequested event,
    Emitter<ResetPasswordConfirmState> emit,
  ) async {
    if (state is ResetPasswordConfirmLoading ||
        state is ResetPasswordCodeVerifying ||
        state is ResetPasswordCodeResending) {
      return;
    }
    _verifiedCode = null;
    emit(const ResetPasswordCodeResending());
    final result = await _authRepository.resetPassword(
      email: event.email.trim().toLowerCase(),
    );
    result.fold(
      (failure) =>
          emit(ResetPasswordConfirmFailure(safeAuthFailureMessage(failure))),
      (_) => emit(const ResetPasswordCodeSent()),
    );
  }

  Future<void> _onVerifyCodeRequested(
    ResetPasswordCodeVerifyRequested event,
    Emitter<ResetPasswordConfirmState> emit,
  ) async {
    if (state is ResetPasswordConfirmLoading ||
        state is ResetPasswordCodeVerifying ||
        state is ResetPasswordCodeResending) {
      return;
    }
    final normalizedEmail = event.email.trim().toLowerCase();
    final emailError = authFormValidator.email(normalizedEmail);
    if (emailError != null) {
      emit(ResetPasswordCodeVerificationFailure(emailError));
      return;
    }
    final normalizedCode = event.code.trim();
    if (!_otpPattern.hasMatch(normalizedCode)) {
      emit(
        const ResetPasswordCodeVerificationFailure(
          'Enter the 6-digit verification code.',
        ),
      );
      return;
    }
    if (_verifiedCode == normalizedCode) {
      emit(const ResetPasswordCodeVerified());
      return;
    }

    emit(const ResetPasswordCodeVerifying());
    final result = await _authRepository.verifyResetOtp(
      email: normalizedEmail,
      code: normalizedCode,
    );
    result.fold(
      (failure) => emit(
        ResetPasswordCodeVerificationFailure(safeAuthFailureMessage(failure)),
      ),
      (_) {
        _verifiedCode = normalizedCode;
        emit(const ResetPasswordCodeVerified());
      },
    );
  }

  Future<void> _onResetPasswordConfirmSubmitted(
    ResetPasswordConfirmSubmitted event,
    Emitter<ResetPasswordConfirmState> emit,
  ) async {
    if (state is ResetPasswordConfirmLoading ||
        state is ResetPasswordCodeVerifying ||
        state is ResetPasswordCodeResending) {
      return;
    }
    final trimmedPassword = event.newPassword;
    final normalizedEmail = event.email.trim().toLowerCase();
    final normalizedCode = event.code.trim();
    if (!_otpPattern.hasMatch(normalizedCode)) {
      emit(
        const ResetPasswordConfirmFailure(
          'Enter the 6-digit verification code.',
        ),
      );
      return;
    }
    final validationError = authFormValidator.password(trimmedPassword);
    if (validationError != null) {
      emit(ResetPasswordConfirmFailure(validationError));
      return;
    }

    emit(const ResetPasswordConfirmLoading());

    final result = await _authRepository.confirmResetPassword(
      email: normalizedEmail,
      code: normalizedCode,
      newPassword: trimmedPassword,
    );

    result.fold(
      (failure) =>
          emit(ResetPasswordConfirmFailure(safeAuthFailureMessage(failure))),
      (_) => emit(const ResetPasswordConfirmSuccess()),
    );
  }
}
