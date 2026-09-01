import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger/src/features/auth/domain/entities/auth_credentials.dart';
import 'package:passenger/src/features/auth/domain/repositories/passenger_auth_repository.dart';
import 'package:passenger/src/features/auth/presentation/validation/auth_failure_message.dart';
import 'package:passenger/src/features/auth/presentation/validation/auth_form_validator.dart';
import 'package:foundation/foundation.dart';

part 'sign_up_event.dart';
part 'sign_up_state.dart';

class SignUpBloc(this._authRepository) extends Bloc<SignUpEvent, SignUpState> {
  final PassengerAuthRepository _authRepository;

  this : super(const SignUpInitial()) {
    on<SignUpSubmitted>(_onSignUpSubmitted);
  }

  Future<void> _onSignUpSubmitted(
    SignUpSubmitted event,
    Emitter<SignUpState> emit,
  ) async {
    final normalizedName = event.name.trim();
    final normalizedEmail = event.email.trim();
    final normalizedPhone = event.phone.trim();
    final normalizedPassword = event.password;

    final validationError =
        authFormValidator.name(normalizedName) ??
        authFormValidator.email(normalizedEmail) ??
        authFormValidator.phone(normalizedPhone) ??
        authFormValidator.password(normalizedPassword);
    if (validationError != null) {
      emit(SignUpFailure(validationError));
      return;
    }

    emit(const SignUpLoading());

    final result = await _authRepository.registerPassenger(
      name: normalizedName,
      email: normalizedEmail,
      phone: normalizedPhone,
      password: normalizedPassword,
    );

    result.fold(
      (failure) => emit(SignUpFailure(safeAuthFailureMessage(failure))),
      (response) {
        final needsVerification = response['needsVerification'] == true;
        if (needsVerification) {
          emit(SignUpNeedsVerification(normalizedEmail));
        } else {
          final userData = response['user'];
          final user = userData is Map
              ? Map<String, dynamic>.from(userData)
              : const <String, dynamic>{};
          final credentials = PassengerAuthCredentials(
            passengerId:
                response['passengerId']?.toString() ??
                user['id']?.toString() ??
                '',
            passengerName: user['name']?.toString() ?? normalizedName,
            passengerEmail: user['email']?.toString() ?? normalizedEmail,
            passengerPhone: user['phone']?.toString() ?? normalizedPhone,
            token: response['token']?.toString() ?? '',
            refreshToken: response['refreshToken']?.toString() ?? '',
          );
          if (credentials.passengerId.isEmpty || credentials.token.isEmpty) {
            emit(
              SignUpFailure(
                ErrorHandler.getErrorMessage(const ServerFailure()),
              ),
            );
            return;
          }
          emit(SignUpSuccess(credentials));
        }
      },
    );
  }
}
