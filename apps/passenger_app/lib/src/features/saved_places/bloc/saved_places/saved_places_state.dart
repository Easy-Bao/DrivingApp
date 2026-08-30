import 'package:equatable/equatable.dart';
import 'package:passenger_app/src/features/saved_places/domain/entities/saved_place.dart';
import 'package:passenger_app/src/features/saved_places/domain/saved_place_defaults.dart';

enum SavedPlacesErrorSource { load, persistence }

class SavedPlacesState extends Equatable {
  final List<SavedPlace> places;
  final bool isLoading;
  final String? errorMessage;
  final SavedPlacesErrorSource? errorSource;

  const SavedPlacesState({
    this.places = const [],
    this.isLoading = true,
    this.errorMessage,
    this.errorSource,
  });

  SavedPlacesState copyWith({
    List<SavedPlace>? places,
    bool? isLoading,
    String? errorMessage,
    SavedPlacesErrorSource? errorSource,
    bool clearErrorMessage = false,
  }) {
    return SavedPlacesState(
      places: places ?? this.places,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
      errorSource: clearErrorMessage ? null : errorSource ?? this.errorSource,
    );
  }

  int get defaultPlaceIndex => defaultSavedPlaceIndex(places);

  SavedPlace? get defaultPlace => defaultSavedPlace(places);

  @override
  List<Object?> get props => [places, isLoading, errorMessage, errorSource];
}
