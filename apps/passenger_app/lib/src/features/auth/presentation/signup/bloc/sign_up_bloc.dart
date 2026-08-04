import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/features/auth/domain/entities/auth_credentials.dart';
import 'package:passenger_app/src/features/auth/domain/usecases/register_use_case.dart';
import 'package:passenger_app/src/features/auth/presentation/signup/bloc/sign_up_event.dart';
import 'package:passenger_app/src/features/auth/presentation/signup/bloc/sign_up_state.dart';
import 'package:passenger_app/src/features/auth/presentation/validation/auth_failure_message.dart';
import 'package:passenger_app/src/features/auth/presentation/validation/auth_form_validator.dart';

export 'package:passenger_app/src/features/auth/presentation/signup/bloc/sign_up_event.dart';
export 'package:passenger_app/src/features/auth/presentation/signup/bloc/sign_up_state.dart';

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
    final normalizedPassword = event.password;

    final validationError =
        authFormValidator.name(normalizedName) ??
        authFormValidator.email(normalizedEmail) ??
        authFormValidator.phone(normalizedPhone) ??
        authFormValidator.password(normalizedPassword);
    if (validationError != null) {
      emit(SignUpFailure(validationError));
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
      (failure) => emit(SignUpFailure(safeAuthFailureMessage(failure))),
      (response) {
        final needsVerification = response['needsVerification'] == true;
        if (needsVerification) {
          emit(SignUpNeedsVerification(normalizedEmail));
        } else {
          final credentials = AuthCredentials(
            passengerId: response['passengerId']?.toString() ?? '',
            passengerName: normalizedName,
            passengerEmail: normalizedEmail,
            passengerPhone: normalizedPhone,
            token: response['token']?.toString() ?? '',
          );
          emit(SignUpSuccess(credentials));
        }
      },
    );
  }
}
