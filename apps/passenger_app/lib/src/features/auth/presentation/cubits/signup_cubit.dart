import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/features/auth/domain/usecases/register_use_case.dart';
import 'package:passenger_app/src/features/auth/domain/usecases/verify_otp_use_case.dart';
import 'package:passenger_app/src/features/auth/presentation/cubits/signup_state.dart';

class SignUpCubit extends Cubit<SignUpState> {
  final RegisterUseCase _registerUseCase;
  final VerifyOtpUseCase _verifyOtpUseCase;

  SignUpCubit({
    required RegisterUseCase registerUseCase,
    required VerifyOtpUseCase verifyOtpUseCase,
  })  : _registerUseCase = registerUseCase,
        _verifyOtpUseCase = verifyOtpUseCase,
        super(const SignUpInitial());

  Future<void> registerPassenger({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      emit(const SignUpFailure('Please enter a valid email address.'));
      return;
    }
    if (password.length < 8) {
      emit(const SignUpFailure('Password must be at least 8 characters.'));
      return;
    }

    emit(const SignUpLoading());

    final result = await _registerUseCase.execute(
      name: name,
      email: normalizedEmail,
      phone: phone,
      password: password,
    );

    result.fold(
      (failure) => emit(SignUpFailure(failure.message)),
      (_) => emit(SignUpNeedsVerification(normalizedEmail)),
    );
  }

  Future<void> verifyOtpCode({
    required String email,
    required String code,
    required String password,
  }) async {
    emit(const SignUpLoading());

    final result = await _verifyOtpUseCase.execute(
      email: email,
      code: code,
      password: password,
    );

    result.fold(
      (failure) => emit(SignUpFailure(failure.message)),
      (credentials) => emit(SignUpSuccess(credentials)),
    );
  }
}
