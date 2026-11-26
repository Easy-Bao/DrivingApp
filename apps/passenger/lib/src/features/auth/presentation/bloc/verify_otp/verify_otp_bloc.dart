import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:passenger/src/features/auth/presentation/validation/auth_failure_message.dart';

part 'verify_otp_event.dart';
part 'verify_otp_state.dart';

class VerifyOtpBloc(this._authRepository)
    extends Bloc<VerifyOtpEvent, VerifyOtpState> {
  final AuthRepository _authRepository;
  Timer? _timer;
  int _seconds = 60;

  this : super(const VerifyOtpInitial()) {
    on<VerifyOtpTimerStarted>(_onVerifyOtpTimerStarted);
    on<VerifyOtpTimerTicked>(_onVerifyOtpTimerTicked);
    on<VerifyOtpSubmitted>(_onVerifyOtpSubmitted, transformer: droppable());
    on<VerifyOtpResendRequested>(
      _onVerifyOtpResendRequested,
      transformer: droppable(),
    );
  }

  void _onVerifyOtpTimerStarted(
    VerifyOtpTimerStarted event,
    Emitter<VerifyOtpState> emit,
  ) {
    _timer?.cancel();
    _seconds = 60;
    emit(const VerifyOtpTimerTicking(60));
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isClosed) {
        timer.cancel();
        return;
      }
      _seconds--;
      if (_seconds <= 0) {
        _seconds = 0;
        timer.cancel();
        add(const VerifyOtpTimerTicked(secondsRemaining: 0));
      } else {
        add(VerifyOtpTimerTicked(secondsRemaining: _seconds));
      }
    });
  }

  void _onVerifyOtpTimerTicked(
    VerifyOtpTimerTicked event,
    Emitter<VerifyOtpState> emit,
  ) {
    final remaining = event.secondsRemaining <= 0 ? 0 : event.secondsRemaining;
    _seconds = remaining;
    switch (state) {
      case VerifyOtpLoading():
        emit(VerifyOtpLoading(secondsRemaining: remaining));
      case VerifyOtpFailure(:final errorMessage):
        emit(VerifyOtpFailure(errorMessage, secondsRemaining: remaining));
      case VerifyOtpResending():
        emit(VerifyOtpResending(secondsRemaining: remaining));
      case VerifyOtpResendFailure(:final errorMessage):
        emit(VerifyOtpResendFailure(errorMessage));
      case VerifyOtpSuccess():
        return;
      case VerifyOtpInitial() ||
          VerifyOtpTimerTicking() ||
          VerifyOtpTimerExpired() ||
          VerifyOtpResent():
        if (remaining <= 0) {
          emit(const VerifyOtpTimerExpired());
        } else {
          emit(VerifyOtpTimerTicking(remaining));
        }
    }
  }

  Future<void> _onVerifyOtpSubmitted(
    VerifyOtpSubmitted event,
    Emitter<VerifyOtpState> emit,
  ) async {
    final normalizedCode = event.code.trim();
    final normalizedEmail = event.email.trim().toLowerCase();
    if (normalizedCode.length < 6) {
      emit(
        VerifyOtpFailure(
          'Enter the 6-digit code sent to your email.',
          secondsRemaining: _seconds,
        ),
      );
      return;
    }

    emit(VerifyOtpLoading(secondsRemaining: _seconds));

    final result = await _authRepository.verifyOtp(
      email: normalizedEmail,
      code: normalizedCode,
    );

    switch (result) {
      case Err(:final failure):
        emit(
          VerifyOtpFailure(
            safeAuthFailureMessage(failure),
            secondsRemaining: _seconds,
          ),
        );
      case Ok():
        _timer?.cancel();
        emit(VerifyOtpSuccess(secondsRemaining: _seconds));
    }
  }

  Future<void> _onVerifyOtpResendRequested(
    VerifyOtpResendRequested event,
    Emitter<VerifyOtpState> emit,
  ) async {
    _timer?.cancel();
    _seconds = 0;
    emit(const VerifyOtpResending());

    final result = await _authRepository.requestVerificationCode(
      email: event.email.trim().toLowerCase(),
    );

    switch (result) {
      case Err(:final failure):
        emit(VerifyOtpResendFailure(safeAuthFailureMessage(failure)));
      case Ok():
        emit(const VerifyOtpResent());
        add(const VerifyOtpTimerStarted());
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
