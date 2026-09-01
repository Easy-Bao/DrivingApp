import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger/src/features/auth/domain/repositories/passenger_auth_repository.dart';

part 'verify_otp_event.dart';
part 'verify_otp_state.dart';

class VerifyOtpBloc(this._authRepository)
    extends Bloc<VerifyOtpEvent, VerifyOtpState> {
  final PassengerAuthRepository _authRepository;
  Timer? _timer;
  int _seconds = 60;

  this : super(const VerifyOtpInitial()) {
    on<VerifyOtpTimerStarted>(_onVerifyOtpTimerStarted);
    on<VerifyOtpTimerTicked>(_onVerifyOtpTimerTicked);
    on<VerifyOtpSubmitted>(_onVerifyOtpSubmitted);
    on<VerifyOtpResendRequested>(_onVerifyOtpResendRequested);
  }

  void _onVerifyOtpTimerStarted(
    VerifyOtpTimerStarted event,
    Emitter<VerifyOtpState> emit,
  ) {
    _timer?.cancel();
    _seconds = 60;
    emit(const VerifyOtpTimerTicking(60));
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _seconds--;
      if (_seconds <= 0) {
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
    if (event.secondsRemaining <= 0) {
      emit(const VerifyOtpTimerExpired());
    } else {
      emit(VerifyOtpTimerTicking(event.secondsRemaining));
    }
  }

  Future<void> _onVerifyOtpSubmitted(
    VerifyOtpSubmitted event,
    Emitter<VerifyOtpState> emit,
  ) async {
    final normalizedCode = event.code.trim();
    final normalizedEmail = event.email.trim().toLowerCase();
    if (normalizedCode.length < 6) {
      emit(const VerifyOtpFailure('Please enter a 6-digit verification code.'));
      return;
    }

    emit(const VerifyOtpLoading());

    final result = await _authRepository.verifyOtp(
      email: normalizedEmail,
      code: normalizedCode,
    );

    result.fold(
      (_) => emit(
        const VerifyOtpFailure(
          'That code is invalid or has expired. Request a new code and try again.',
        ),
      ),
      (_) => emit(const VerifyOtpSuccess()),
    );
  }

  Future<void> _onVerifyOtpResendRequested(
    VerifyOtpResendRequested event,
    Emitter<VerifyOtpState> emit,
  ) async {
    emit(const VerifyOtpResending());

    final result = await _authRepository.requestVerificationCode(
      email: event.email.trim().toLowerCase(),
    );

    result.fold(
      (_) => emit(
        const VerifyOtpResendFailure(
          "We couldn't send a new code right now. Please try again.",
        ),
      ),
      (_) {
        emit(const VerifyOtpResent());
        add(const VerifyOtpTimerStarted());
      },
    );
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
