import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:passenger_app/src/features/auth/domain/entities/auth_credentials.dart';

part 'generated/sign_in_state.freezed.dart';

@freezed
sealed class SignInState with _$SignInState {
  const factory SignInState.initial() = SignInInitial;
  const factory SignInState.loading() = SignInLoading;
  const factory SignInState.success(AuthCredentials credentials) =
      SignInSuccess;
  const factory SignInState.needsVerification(String email) =
      SignInNeedsVerification;
  const factory SignInState.failure(String errorMessage) = SignInFailure;
}
