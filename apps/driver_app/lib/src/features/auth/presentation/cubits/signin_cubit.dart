import 'package:driver_app/src/features/auth/domain/usecases/authenticate_use_case.dart';
import 'package:driver_app/src/features/auth/presentation/cubits/signin_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SignInCubit extends Cubit<SignInState> {
  final AuthenticateUseCase _authenticateUseCase;

  SignInCubit(this._authenticateUseCase) : super(const SignInInitial());

  Future<void> signIn(String email, String password) async {
    final normalizedEmail = email.trim();
    final normalizedPassword = password.trim();

    if (normalizedEmail.isEmpty || normalizedPassword.isEmpty) {
      emit(const SignInFailure('Email and password are required.'));
      return;
    }

    emit(const SignInLoading());

    final result = await _authenticateUseCase.execute(
      email: normalizedEmail,
      password: normalizedPassword,
    );

    result.fold(
      (failure) => emit(SignInFailure(failure.message)),
      (credentials) => emit(SignInSuccess(credentials)),
    );
  }
}
