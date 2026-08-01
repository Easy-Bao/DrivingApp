import 'package:core_models/CoreModels.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/Features/SavedPlaces/Data/Models/SavedPlaceModel.dart';
import 'package:passenger_app/src/Features/SavedPlaces/Domain/Entities/SavedPlace.dart';
import 'package:passenger_app/src/Features/SavedPlaces/Domain/Repositories/ISavedPlacesRepository.dart';
import 'package:passenger_app/src/Features/SavedPlaces/Presentation/Bloc/SavedPlacesState.dart';

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
