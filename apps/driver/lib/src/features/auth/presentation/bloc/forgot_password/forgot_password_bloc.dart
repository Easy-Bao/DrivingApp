import 'package:driver/src/features/auth/domain/repositories/driver_auth_repository.dart';
import 'package:driver/src/features/auth/presentation/bloc/forgot_password/forgot_password_event.dart';
import 'package:driver/src/features/auth/presentation/bloc/forgot_password/forgot_password_state.dart';
import 'package:foundation/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'forgot_password_event.dart';
export 'forgot_password_state.dart';

class ForgotPasswordBloc(this._authRepository)
    extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  final DriverAuthRepository _authRepository;

  this : super(const ForgotPasswordInitial()) {
    on<ForgotPasswordSubmitted>(_onForgotPasswordSubmitted);
  }

  Future<void> _onForgotPasswordSubmitted(
    ForgotPasswordSubmitted event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    final normalizedEmail = event.email.trim();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      emit(const ForgotPasswordFailure('Please enter a valid email address.'));
      return;
    }

    emit(const ForgotPasswordLoading());

    final result = await _authRepository.resetPassword(email: normalizedEmail);

    result.fold(
      (failure) =>
          emit(ForgotPasswordFailure(ErrorHandler.getErrorMessage(failure))),
      (_) => emit(const ForgotPasswordSuccess()),
    );
  }
}
