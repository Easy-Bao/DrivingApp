import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/features/auth/domain/entities/auth_credentials.dart';
import 'package:passenger_app/src/features/auth/domain/usecases/sign_in_use_case.dart';
import 'package:passenger_app/src/features/auth/view/validation/auth_failure_message.dart';
import 'package:passenger_app/src/features/auth/view/validation/auth_form_validator.dart';

part 'sign_in_event.dart';
part 'sign_in_state.dart';

class SignInBloc extends Bloc<SignInEvent, SignInState> {
  final SignInUseCase _signInUseCase;

  SignInBloc(this._signInUseCase) : super(const SignInInitial()) {
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

    final result = await _signInUseCase.execute(
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
