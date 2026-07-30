import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/profile_state.freezed.dart';

@freezed
abstract class ProfileState with _$ProfileState {
  const factory ProfileState({
    @Default('') String name,
    @Default('') String phone,
    @Default('') String email,
    @Default(false) bool isLoading,
    String? errorMessage,
  }) = _ProfileState;
}
