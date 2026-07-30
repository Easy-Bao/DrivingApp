import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_event.freezed.dart';

@freezed
sealed class AuthEvent with _$AuthEvent {
  const factory AuthEvent.checkRequested() = AuthCheckRequested;
  const factory AuthEvent.loggedIn({
    required String token,
    required String userId,
  }) = AuthLoggedIn;
  const factory AuthEvent.loggedOut() = AuthLoggedOut;
}
