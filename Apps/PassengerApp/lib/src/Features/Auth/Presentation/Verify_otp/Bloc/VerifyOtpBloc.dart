import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/Features/Auth/Domain/Usecases/VerifyOtpUseCase.dart';
import 'package:passenger_app/src/Features/Auth/Presentation/Verify_otp/Bloc/VerifyOtpEvent.dart';
import 'package:passenger_app/src/Features/Auth/Presentation/Verify_otp/Bloc/VerifyOtpState.dart';

export 'package:passenger_app/src/Features/Auth/Presentation/Verify_otp/Bloc/VerifyOtpEvent.dart';
export 'package:passenger_app/src/Features/Auth/Presentation/Verify_otp/Bloc/VerifyOtpState.dart';

class VerifyOtpBloc extends Bloc<VerifyOtpEvent, VerifyOtpState> {
  final VerifyOtpUseCase _verifyOtpUseCase;
  Timer? _timer;
  int _seconds = 60;

  VerifyOtpBloc(this._verifyOtpUseCase)
      : super(const VerifyOtpInitial()) {
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
      emit(
        const VerifyOtpFailure(
          'Please enter a 6-digit verification code.',
        ),
      );
      return;
    }

    emit(const VerifyOtpLoading());

    final result = await _verifyOtpUseCase.execute(
      email: normalizedEmail,
      code: normalizedCode,
      password: event.password,
    );

    result.fold(
      (failure) => emit(VerifyOtpFailure(failure.message)),
      (_) => emit(const VerifyOtpSuccess()),
    );
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
