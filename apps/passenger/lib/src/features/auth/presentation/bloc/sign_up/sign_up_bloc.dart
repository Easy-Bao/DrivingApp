import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/auth/domain/entities/auth_credentials.dart';
import 'package:passenger/src/features/auth/domain/entities/sign_up_result.dart';
import 'package:passenger/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:passenger/src/features/auth/presentation/validation/auth_failure_message.dart';
import 'package:passenger/src/features/auth/presentation/validation/auth_form_validator.dart';

part 'sign_up_event.dart';
part 'sign_up_state.dart';

class SignUpBloc(this._authRepository) extends Bloc<SignUpEvent, SignUpState> {
  final AuthRepository _authRepository;

  this : super(const SignUpInitial()) {
    on<SignUpSubmitted>(_onSignUpSubmitted, transformer: droppable());
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

    final result = await _authRepository.registerPassenger(
      name: normalizedName,
      email: normalizedEmail,
      phone: normalizedPhone,
      password: normalizedPassword,
    );

    switch (result) {
      case Err(:final failure):
        emit(SignUpFailure(safeAuthFailureMessage(failure)));
      case Ok(:final value):
        switch (value) {
          case SignUpVerificationRequired(:final email):
            emit(SignUpNeedsVerification(email));
          case SignUpAuthenticated(:final credentials):
            emit(SignUpSuccess(credentials));
        }
    }
  }
}
