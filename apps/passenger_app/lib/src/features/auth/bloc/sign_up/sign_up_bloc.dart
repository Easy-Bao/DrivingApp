import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/features/auth/domain/entities/auth_credentials.dart';
import 'package:passenger_app/src/features/auth/domain/usecases/register_use_case.dart';
import 'package:passenger_app/src/features/auth/view/validation/auth_failure_message.dart';
import 'package:passenger_app/src/features/auth/view/validation/auth_form_validator.dart';

part 'sign_up_event.dart';
part 'sign_up_state.dart';

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
          final userData = response['user'];
          final user = userData is Map
              ? Map<String, dynamic>.from(userData)
              : const <String, dynamic>{};
          final credentials = AuthCredentials(
            passengerId:
                response['passengerId']?.toString() ??
                user['id']?.toString() ??
                '',
            passengerName: user['name']?.toString() ?? normalizedName,
            passengerEmail: user['email']?.toString() ?? normalizedEmail,
            passengerPhone: user['phone']?.toString() ?? normalizedPhone,
            token: response['token']?.toString() ?? '',
          );
          if (credentials.passengerId.isEmpty || credentials.token.isEmpty) {
            emit(
              const SignUpFailure('Registration returned an invalid session.'),
            );
            return;
          }
          emit(SignUpSuccess(credentials));
        }
      },
    );
  }
}
