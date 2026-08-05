import 'package:equatable/equatable.dart';
import 'package:passenger_app/src/features/saved_places/domain/entities/saved_place.dart';

class SavedPlacesState extends Equatable {
  final List<SavedPlace> places;
  final bool isLoading;
  final String? errorMessage;

  const SavedPlacesState({
    this.places = const [],
    this.isLoading = true,
    this.errorMessage,
  });

  SavedPlacesState copyWith({
    List<SavedPlace>? places,
    bool? isLoading,
    String? errorMessage,
  }) {
    return SavedPlacesState(
      places: places ?? this.places,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [places, isLoading, errorMessage];
}
