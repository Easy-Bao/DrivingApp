import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:driver/src/features/auth/domain/entities/auth_credentials.dart';
import 'package:driver/src/features/auth/domain/repositories/driver_auth_repository.dart';
import 'package:driver/src/features/auth/presentation/bloc/sign_in/sign_in_event.dart';
import 'package:driver/src/features/auth/presentation/bloc/sign_in/sign_in_failure_message.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'sign_in_event.dart';

part 'sign_in_state.dart';

class SignInBloc(this._authRepository) extends Bloc<SignInEvent, SignInState> {
  final DriverAuthRepository _authRepository;

  this : super(const SignInInitial()) {
    on<SignInSubmitted>(_onSignInSubmitted, transformer: droppable());
  }

  Future<void> _onSignInSubmitted(
    SignInSubmitted event,
    Emitter<SignInState> emit,
  ) async {
    final normalizedEmail = event.email.trim().toLowerCase();
    final password = event.password;

    if (normalizedEmail.isEmpty) {
      emit(const SignInFailure('Enter your email address.'));
      return;
    }
    if (!normalizedEmail.contains('@')) {
      emit(const SignInFailure('Enter a valid email address.'));
      return;
    }
    if (password.isEmpty) {
      emit(const SignInFailure('Enter your password.'));
      return;
    }

    emit(const SignInLoading());

    final result = await _authRepository.authenticate(
      email: normalizedEmail,
      password: password,
    );

    result.fold(
      (failure) => emit(SignInFailure(signInFailureMessage(failure))),
      (credentials) => emit(SignInSuccess(credentials)),
    );
  }
}
