import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';

@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.initial() = AuthInitial;
  const factory AuthState.authenticated({
    required String token,
    required String userId,
  }) = Authenticated;
  const factory AuthState.unauthenticated() = Unauthenticated;
}
