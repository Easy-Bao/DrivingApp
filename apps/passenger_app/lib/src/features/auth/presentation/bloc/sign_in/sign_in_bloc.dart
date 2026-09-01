import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/features/auth/domain/entities/auth_credentials.dart';
import 'package:passenger_app/src/features/auth/domain/repositories/passenger_auth_repository.dart';
import 'package:passenger_app/src/features/auth/presentation/bloc/sign_in/sign_in_event.dart';
import 'package:passenger_app/src/features/auth/presentation/validation/auth_failure_message.dart';
import 'package:passenger_app/src/features/auth/presentation/validation/auth_form_validator.dart';

export 'sign_in_event.dart';

part 'sign_in_state.dart';

class SignInBloc extends Bloc<SignInEvent, SignInState> {
  final PassengerAuthRepository _authRepository;

  SignInBloc(this._authRepository) : super(const SignInInitial()) {
    on<SignInSubmitted>(_onSignInSubmitted);
  }

  Future<void> _onSignInSubmitted(
    SignInSubmitted event,
    Emitter<SignInState> emit,
  ) async {
    final normalizedEmail = event.email.trim().toLowerCase();
    final password = event.password;

    final emailError = authFormValidator.email(normalizedEmail);
    final passwordError = authFormValidator.password(
      password,
      minimumLength: 1,
    );
    if (emailError != null || passwordError != null) {
      emit(SignInFailure(emailError ?? passwordError!));
      return;
    }

    emit(const SignInLoading());

    final result = await _authRepository.authenticate(
      email: normalizedEmail,
      password: password,
    );

    result.fold(
      (failure) => emit(SignInFailure(safeAuthFailureMessage(failure))),
      (credentials) {
        if (credentials.needsVerification) {
          emit(SignInNeedsVerification(normalizedEmail));
        } else {
          emit(SignInSuccess(credentials));
        }
      },
    );
  }
}
