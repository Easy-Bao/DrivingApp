import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/features/auth/domain/usecases/verify_otp_use_case.dart';
import 'package:passenger_app/src/features/auth/presentation/verify_otp/bloc/verify_otp_event.dart';
import 'package:passenger_app/src/features/auth/presentation/verify_otp/bloc/verify_otp_state.dart';

export 'package:passenger_app/src/features/auth/presentation/verify_otp/bloc/verify_otp_event.dart';
export 'package:passenger_app/src/features/auth/presentation/verify_otp/bloc/verify_otp_state.dart';

class VerifyOtpBloc extends Bloc<VerifyOtpEvent, VerifyOtpState> {
  final VerifyOtpUseCase _verifyOtpUseCase;
  Timer? _timer;
  int _seconds = 60;

  VerifyOtpBloc(this._verifyOtpUseCase)
      : super(const VerifyOtpState.initial()) {
    on<VerifyOtpTimerStarted>(_onVerifyOtpTimerStarted);
    on<VerifyOtpTimerTicked>(_onVerifyOtpTimerTicked);
    on<VerifyOtpSubmitted>(_onVerifyOtpSubmitted);
  }

  void _onVerifyOtpTimerStarted(
    VerifyOtpTimerStarted event,
    Emitter<VerifyOtpState> emit,
  ) {
    _timer?.cancel();
    _seconds = 60;
    emit(const VerifyOtpState.timerTicking(60));
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _seconds--;
      if (_seconds <= 0) {
        timer.cancel();
        add(const VerifyOtpEvent.timerTicked(secondsRemaining: 0));
      } else {
        add(VerifyOtpEvent.timerTicked(secondsRemaining: _seconds));
      }
    });
  }

  void _onVerifyOtpTimerTicked(
    VerifyOtpTimerTicked event,
    Emitter<VerifyOtpState> emit,
  ) {
    if (event.secondsRemaining <= 0) {
      emit(const VerifyOtpState.timerExpired());
    } else {
      emit(VerifyOtpState.timerTicking(event.secondsRemaining));
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
        const VerifyOtpState.failure(
          'Please enter a 6-digit verification code.',
        ),
      );
      return;
    }

    emit(const VerifyOtpState.loading());

    final result = await _verifyOtpUseCase.execute(
      email: normalizedEmail,
      code: normalizedCode,
      password: event.password,
    );

    result.fold(
      (failure) => emit(VerifyOtpState.failure(failure.message)),
      (_) => emit(const VerifyOtpState.success()),
    );
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
