import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/home_state.freezed.dart';

@freezed
abstract class HomeState with _$HomeState {
  const factory HomeState({
    @Default(false) bool isLoading,
    @Default('') String currentAddress,
    @Default([]) List<Map<String, dynamic>> recentLocations,
  }) = _HomeState;
}
