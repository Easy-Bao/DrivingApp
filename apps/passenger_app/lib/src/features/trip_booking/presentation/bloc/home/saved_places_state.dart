import 'package:equatable/equatable.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/views/home/models/saved_place_model.dart';

/**
 * Immutable state snapshot for the [SavedPlacesCubit].
 *
 * [places] holds the current ordered list of shortcut chips shown on the
 * home screen. [isLoading] is true only during the initial async load from
 * SharedPreferences before the first frame renders the chip row.
 */
class SavedPlacesState extends Equatable {
  final List<SavedPlaceModel> places;
  final bool isLoading;

  const SavedPlacesState({
    this.places = const [],
    this.isLoading = true,
  });

  SavedPlacesState copyWith({
    List<SavedPlaceModel>? places,
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
