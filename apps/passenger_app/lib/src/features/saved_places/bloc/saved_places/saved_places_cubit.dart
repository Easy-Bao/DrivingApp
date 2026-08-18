import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/features/saved_places/bloc/saved_places/saved_places_state.dart';
import 'package:passenger_app/src/features/saved_places/data/models/saved_place_model.dart';
import 'package:passenger_app/src/features/saved_places/domain/entities/saved_place.dart';
import 'package:passenger_app/src/features/saved_places/domain/repositories/i_saved_places_repository.dart';
import 'package:shared_core/shared_core.dart';

class SavedPlacesCubit extends Cubit<SavedPlacesState> {
  final ISavedPlacesRepository _repository;

  SavedPlacesCubit({required ISavedPlacesRepository repository})
    : _repository = repository,
      super(const SavedPlacesState());

  Future<void> loadPlaces() async {
    emit(state.copyWith(isLoading: true, clearErrorMessage: true));

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
          places: state.places,
          isLoading: false,
          errorMessage: ErrorHandler.getErrorMessage(error),
        ),
      );
    }
  }

  Future<void> addPlace(SavedPlace place) async {
    final updated = [...state.places, place];
    emit(state.copyWith(places: updated, clearErrorMessage: true));
    try {
      await _repository.savePlaces(updated);
    } catch (error) {
      emit(state.copyWith(errorMessage: ErrorHandler.getErrorMessage(error)));
    }
  }

  Future<void> removePlace(int index) async {
    if (index < 0 || index >= state.places.length) return;
    final updated = [...state.places]..removeAt(index);
    emit(state.copyWith(places: updated, clearErrorMessage: true));
    try {
      await _repository.savePlaces(updated);
    } catch (error) {
      emit(state.copyWith(errorMessage: ErrorHandler.getErrorMessage(error)));
    }
  }

  Future<void> replacePlace(int index, SavedPlace place) async {
    if (index < 0 || index >= state.places.length) return;
    final updated = [...state.places]..[index] = place;
    emit(state.copyWith(places: updated, clearErrorMessage: true));
    try {
      await _repository.savePlaces(updated);
    } catch (error) {
      emit(state.copyWith(errorMessage: ErrorHandler.getErrorMessage(error)));
    }
  }
}
