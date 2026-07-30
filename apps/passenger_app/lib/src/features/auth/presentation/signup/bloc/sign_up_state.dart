import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:passenger_app/src/features/auth/domain/entities/auth_credentials.dart';

part 'generated/sign_up_state.freezed.dart';

@freezed
sealed class SignUpState with _$SignUpState {
  const factory SignUpState.initial() = SignUpInitial;
  const factory SignUpState.loading() = SignUpLoading;
  const factory SignUpState.needsVerification(String email) =
      SignUpNeedsVerification;
  const factory SignUpState.success(AuthCredentials credentials) =
      SignUpSuccess;
  const factory SignUpState.failure(String errorMessage) = SignUpFailure;
}
