import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/features/auth/domain/entities/auth_credentials.dart';
import 'package:passenger_app/src/features/auth/domain/usecases/register_use_case.dart';
import 'package:passenger_app/src/features/auth/presentation/signup/bloc/sign_up_event.dart';
import 'package:passenger_app/src/features/auth/presentation/signup/bloc/sign_up_state.dart';

export 'package:passenger_app/src/features/auth/presentation/signup/bloc/sign_up_event.dart';
export 'package:passenger_app/src/features/auth/presentation/signup/bloc/sign_up_state.dart';

class SignUpBloc extends Bloc<SignUpEvent, SignUpState> {
  final RegisterUseCase _registerUseCase;

  SignUpBloc(this._registerUseCase) : super(const SignUpState.initial()) {
    on<SignUpSubmitted>(_onSignUpSubmitted);
  }

  Future<void> _onSignUpSubmitted(
    SignUpSubmitted event,
    Emitter<SignUpState> emit,
  ) async {
    final normalizedName = event.name.trim();
    final normalizedEmail = event.email.trim();
    final normalizedPhone = event.phone.trim();
    final normalizedPassword = event.password.trim();

    if (normalizedName.isEmpty) {
      emit(const SignUpState.failure('Please enter your full name'));
      return;
    }
    if (normalizedEmail.isEmpty) {
      emit(const SignUpState.failure('Please enter email address'));
      return;
    }
    if (!normalizedEmail.contains('@')) {
      emit(const SignUpState.failure('Please enter a valid email address'));
      return;
    }
    if (normalizedPhone.isEmpty) {
      emit(const SignUpState.failure('Please enter phone number'));
      return;
    }
    if (normalizedPassword.length < 6) {
      emit(
        const SignUpState.failure(
          'Password must be at least 6 characters long',
        ),
      );
      return;
    }

    emit(const SignUpState.loading());

    final result = await _registerUseCase.execute(
      name: normalizedName,
      email: normalizedEmail,
      phone: normalizedPhone,
      password: normalizedPassword,
    );

    result.fold(
      (failure) => emit(SignUpState.failure(failure.message)),
      (response) {
        final needsVerification = response['needsVerification'] == true;
        if (needsVerification) {
          emit(SignUpState.needsVerification(normalizedEmail));
        } else {
          final credentials = AuthCredentials(
            passengerId: response['passengerId'] as String? ?? '',
            passengerName: normalizedName,
            passengerEmail: normalizedEmail,
            passengerPhone: normalizedPhone,
            token: response['token'] as String? ?? '',
          );
          emit(SignUpState.success(credentials));
        }
      },
    );
  }
}
