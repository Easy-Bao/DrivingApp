import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/features/auth/domain/usecases/verify_otp_use_case.dart';
import 'package:passenger_app/src/features/auth/presentation/cubits/verify_otp_state.dart';

class VerifyOtpCubit extends Cubit<VerifyOtpState> {
  final VerifyOtpUseCase _verifyOtpUseCase;
  Timer? _timer;
  int _seconds = 60;

  VerifyOtpCubit(this._verifyOtpUseCase) : super(const VerifyOtpInitial());

  void startResendTimer() {
    _timer?.cancel();
    _seconds = 60;
    emit(const VerifyOtpTimerTicking(60));
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _seconds--;
      if (_seconds <= 0) {
        timer.cancel();
        emit(const VerifyOtpTimerExpired());
      } else {
        emit(VerifyOtpTimerTicking(_seconds));
      }
    });
  }

  Future<void> verifyOtp({
    required String email,
    required String code,
    String password = '',
  }) async {
    final normalizedCode = code.trim();
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedCode.length < 6) {
      emit(const VerifyOtpFailure('Please enter a 6-digit verification code.'));
      return;
    }

    emit(const VerifyOtpLoading());

    final result = await _verifyOtpUseCase.execute(
      email: normalizedEmail,
      code: normalizedCode,
      password: password,
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
