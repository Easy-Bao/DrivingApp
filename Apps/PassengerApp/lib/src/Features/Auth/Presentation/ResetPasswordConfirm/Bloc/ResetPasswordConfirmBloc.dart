import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/Features/Auth/Domain/Usecases/ConfirmResetPasswordUseCase.dart';
import 'package:passenger_app/src/Features/Auth/Presentation/ResetPasswordConfirm/Bloc/ResetPasswordConfirmEvent.dart';
import 'package:passenger_app/src/Features/Auth/Presentation/ResetPasswordConfirm/Bloc/ResetPasswordConfirmState.dart';

export 'package:passenger_app/src/Features/Auth/Presentation/ResetPasswordConfirm/Bloc/ResetPasswordConfirmEvent.dart';
export 'package:passenger_app/src/Features/Auth/Presentation/ResetPasswordConfirm/Bloc/ResetPasswordConfirmState.dart';

class ResetPasswordConfirmBloc
    extends Bloc<ResetPasswordConfirmEvent, ResetPasswordConfirmState> {
  final ConfirmResetPasswordUseCase _confirmResetPasswordUseCase;

  ResetPasswordConfirmBloc(this._confirmResetPasswordUseCase)
      : super(const ResetPasswordConfirmInitial()) {
    on<ResetPasswordConfirmSubmitted>(_onResetPasswordConfirmSubmitted);
  }

  Future<void> _onResetPasswordConfirmSubmitted(
    ResetPasswordConfirmSubmitted event,
    Emitter<ResetPasswordConfirmState> emit,
  ) async {
    final trimmedPassword = event.newPassword.trim();
    final normalizedEmail = event.email.trim().toLowerCase();
    if (trimmedPassword.length < 8) {
      emit(
        const ResetPasswordConfirmFailure(
          'Password must be at least 8 characters.',
        ),
      );
      return;
    }

    emit(const ResetPasswordConfirmLoading());

    final result = await _confirmResetPasswordUseCase.execute(
      email: normalizedEmail,
      code: event.code,
      newPassword: trimmedPassword,
    );

    result.fold(
      (failure) => emit(ResetPasswordConfirmFailure(failure.message)),
      (_) => emit(const ResetPasswordConfirmSuccess()),
    );
  }
}
