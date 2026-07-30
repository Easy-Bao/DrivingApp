import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/sign_up_event.freezed.dart';

@freezed
sealed class SignUpEvent with _$SignUpEvent {
  const factory SignUpEvent.submitted({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) = SignUpSubmitted;
}
