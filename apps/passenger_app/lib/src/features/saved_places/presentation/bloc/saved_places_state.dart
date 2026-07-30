import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:passenger_app/src/features/saved_places/domain/entities/saved_place.dart';

part 'generated/saved_places_state.freezed.dart';

@freezed
abstract class SavedPlacesState with _$SavedPlacesState {
  const factory SavedPlacesState({
    @Default([]) List<SavedPlace> places,
    @Default(true) bool isLoading,
    String? errorMessage,
  }) = _SavedPlacesState;
}
