import 'package:core_models/core_models.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/features/saved_places/data/models/saved_place_model.dart';
import 'package:passenger_app/src/features/saved_places/domain/entities/saved_place.dart';
import 'package:passenger_app/src/features/saved_places/domain/repositories/i_saved_places_repository.dart';
import 'package:passenger_app/src/features/saved_places/presentation/bloc/saved_places_state.dart';

class SavedPlacesCubit extends Cubit<SavedPlacesState> {
  final ISavedPlacesRepository _repository;

  SavedPlacesCubit({required ISavedPlacesRepository repository})
    : _repository = repository,
      super(const SavedPlacesState());

  Future<void> loadPlaces() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final rawPlaces = await _repository.loadPlaces();
      final models = rawPlaces
          .map((raw) => SavedPlaceModel.fromJson(raw))
          .toList();
      emit(
        SavedPlacesState(places: models, isLoading: false, errorMessage: null),
      );
    } catch (error) {
      emit(
        SavedPlacesState(
          places: const [],
          isLoading: false,
          errorMessage: ErrorHandler.getErrorMessage(error),
        ),
      );
    }
  }

  Future<void> addPlace(SavedPlace place) async {
    final updated = [...state.places, place];
    emit(state.copyWith(places: updated, errorMessage: null));
    try {
      await _repository.savePlaces(updated);
    } catch (error) {
      emit(state.copyWith(errorMessage: ErrorHandler.getErrorMessage(error)));
    }
  }

  Future<void> removePlace(int index) async {
    if (index < 0 || index >= state.places.length) return;
    final updated = [...state.places]..removeAt(index);
    emit(state.copyWith(places: updated, errorMessage: null));
    try {
      await _repository.savePlaces(updated);
    } catch (error) {
      emit(state.copyWith(errorMessage: ErrorHandler.getErrorMessage(error)));
    }
  }
}
