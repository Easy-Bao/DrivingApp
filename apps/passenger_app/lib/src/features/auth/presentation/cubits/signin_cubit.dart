import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/features/auth/domain/usecases/sign_in_use_case.dart';
import 'package:passenger_app/src/features/auth/presentation/cubits/signin_state.dart';

class SignInCubit extends Cubit<SignInState> {
  final SignInUseCase _signInUseCase;

  SignInCubit(this._signInUseCase) : super(const SignInInitial());

  Future<void> signIn(String email, String password) async {
    final normalizedEmail = email.trim();
    final normalizedPassword = password.trim();

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
