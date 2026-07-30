import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/sign_in_event.freezed.dart';

@freezed
sealed class SignInEvent with _$SignInEvent {
  const factory SignInEvent.submitted({
    required String email,
    required String password,
  }) = SignInSubmitted;
}
