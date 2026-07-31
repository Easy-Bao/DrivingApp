import 'package:driver_app/src/Features/Auth/Domain/Usecases/SignInUseCase.dart';
import 'package:driver_app/src/Features/Auth/Presentation/Signin/Bloc/SignInEvent.dart';
import 'package:driver_app/src/Features/Auth/Presentation/Signin/Bloc/SignInState.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'package:driver_app/src/features/auth/presentation/signin/bloc/sign_in_event.dart';
export 'package:driver_app/src/features/auth/presentation/signin/bloc/sign_in_state.dart';

class SignInBloc extends Bloc<SignInEvent, SignInState> {
  final SignInUseCase _signInUseCase;

  SignInBloc(this._signInUseCase) : super(const SignInState.initial()) {
    on<SignInSubmitted>(_onSignInSubmitted);
  }

  Future<void> _onSignInSubmitted(
    SignInSubmitted event,
    Emitter<SignInState> emit,
  ) async {
    final normalizedEmail = event.email.trim();
    final normalizedPassword = event.password.trim();

    if (normalizedEmail.isEmpty) {
      emit(const SignInState.failure('Please enter email'));
      return;
    }
    if (!normalizedEmail.contains('@')) {
      emit(const SignInState.failure('Please enter a valid email'));
      return;
    }
    if (normalizedPassword.isEmpty) {
      emit(const SignInState.failure('Please enter password'));
      return;
    }

    emit(const SignInState.loading());

    final result = await _signInUseCase.execute(
      email: normalizedEmail,
      password: normalizedPassword,
    );

    result.fold(
      (failure) => emit(SignInState.failure(failure.message)),
      (credentials) => emit(SignInState.success(credentials)),
    );
  }
}
