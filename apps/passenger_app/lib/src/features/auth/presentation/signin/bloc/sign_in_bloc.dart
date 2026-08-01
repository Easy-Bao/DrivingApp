import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/features/auth/domain/usecases/sign_in_use_case.dart';
import 'package:passenger_app/src/features/auth/presentation/signin/bloc/sign_in_event.dart';
import 'package:passenger_app/src/features/auth/presentation/signin/bloc/sign_in_state.dart';

export 'package:passenger_app/src/features/auth/presentation/signin/bloc/sign_in_event.dart';
export 'package:passenger_app/src/features/auth/presentation/signin/bloc/sign_in_state.dart';

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

    if (normalizedEmail.isEmpty) {
      emit(const SignInFailure('Please enter email'));
      return;
    }
    if (!normalizedEmail.contains('@')) {
      emit(const SignInFailure('Please enter a valid email'));
      return;
    }
    if (password.isEmpty) {
      emit(const SignInFailure('Please enter password'));
      return;
    }

    emit(const SignInLoading());

    final result = await _signInUseCase.execute(
      email: normalizedEmail,
      password: password,
    );

    result.fold((failure) => emit(SignInFailure(failure.message)), (
      credentials,
    ) {
      if (credentials.needsVerification) {
        emit(SignInNeedsVerification(normalizedEmail));
      } else {
        emit(SignInSuccess(credentials));
      }
    });
  }
}
