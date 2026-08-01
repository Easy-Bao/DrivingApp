import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/Features/Auth/Domain/Usecases/SignInUseCase.dart';
import 'package:passenger_app/src/Features/Auth/Presentation/Signin/Bloc/SignInEvent.dart';
import 'package:passenger_app/src/Features/Auth/Presentation/Signin/Bloc/SignInState.dart';

export 'package:passenger_app/src/Features/Auth/Presentation/Signin/Bloc/SignInEvent.dart';
export 'package:passenger_app/src/Features/Auth/Presentation/Signin/Bloc/SignInState.dart';

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
    final normalizedPassword = event.password.trim();

    if (normalizedEmail.isEmpty) {
      emit(const SignInFailure('Please enter email'));
      return;
    }
    if (!normalizedEmail.contains('@')) {
      emit(const SignInFailure('Please enter a valid email'));
      return;
    }
    if (normalizedPassword.isEmpty) {
      emit(const SignInFailure('Please enter password'));
      return;
    }

    emit(const SignInLoading());

    final result = await _signInUseCase.execute(
      email: normalizedEmail,
      password: normalizedPassword,
    );

    result.fold(
      (failure) => emit(SignInFailure(failure.message)),
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
