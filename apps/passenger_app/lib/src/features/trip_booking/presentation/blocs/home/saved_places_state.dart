import 'package:equatable/equatable.dart';
import 'package:passenger_app/src/features/trip_booking/domain/entities/saved_place.dart';

/**
 * Immutable state snapshot for the [SavedPlacesCubit].
 */
class SavedPlacesState extends Equatable {
  final List<SavedPlace> places;
  final bool isLoading;

  const SavedPlacesState({
    this.places = const [],
    this.isLoading = true,
  });

  SavedPlacesState copyWith({
    List<SavedPlace>? places,
    bool? isLoading,
  }) {
    return SavedPlacesState(
      places: places ?? this.places,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [places, isLoading];
}
