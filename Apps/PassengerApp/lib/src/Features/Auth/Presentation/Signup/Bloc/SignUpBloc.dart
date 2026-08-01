import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/Features/Auth/Domain/Entities/AuthCredentials.dart';
import 'package:passenger_app/src/Features/Auth/Domain/Usecases/RegisterUseCase.dart';
import 'package:passenger_app/src/Features/Auth/Presentation/Signup/Bloc/SignUpEvent.dart';
import 'package:passenger_app/src/Features/Auth/Presentation/Signup/Bloc/SignUpState.dart';

export 'package:passenger_app/src/Features/Auth/Presentation/Signup/Bloc/SignUpEvent.dart';
export 'package:passenger_app/src/Features/Auth/Presentation/Signup/Bloc/SignUpState.dart';

class SignUpBloc extends Bloc<SignUpEvent, SignUpState> {
  final RegisterUseCase _registerUseCase;

  SignUpBloc(this._registerUseCase) : super(const SignUpInitial()) {
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
      emit(const SignUpFailure('Please enter your full name'));
      return;
    }
    if (normalizedEmail.isEmpty) {
      emit(const SignUpFailure('Please enter email address'));
      return;
    }
    if (!normalizedEmail.contains('@')) {
      emit(const SignUpFailure('Please enter a valid email address'));
      return;
    }
    if (normalizedPhone.isEmpty) {
      emit(const SignUpFailure('Please enter phone number'));
      return;
    }
    if (normalizedPassword.length < 6) {
      emit(
        const SignUpFailure(
          'Password must be at least 6 characters long',
        ),
      );
      return;
    }

    emit(const SignUpLoading());

    final result = await _registerUseCase.execute(
      name: normalizedName,
      email: normalizedEmail,
      phone: normalizedPhone,
      password: normalizedPassword,
    );

    result.fold(
      (failure) => emit(SignUpFailure(failure.message)),
      (response) {
        final needsVerification = response['needsVerification'] == true;
        if (needsVerification) {
          emit(SignUpNeedsVerification(normalizedEmail));
        } else {
          final credentials = AuthCredentials(
            passengerId: response['passengerId'] as String? ?? '',
            passengerName: normalizedName,
            passengerEmail: normalizedEmail,
            passengerPhone: normalizedPhone,
            token: response['token'] as String? ?? '',
          );
          emit(SignUpSuccess(credentials));
        }
      },
    );
  }
}
