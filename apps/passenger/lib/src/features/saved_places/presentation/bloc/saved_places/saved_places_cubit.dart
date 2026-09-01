import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/saved_places/data/models/saved_place_model.dart';
import 'package:passenger/src/features/saved_places/domain/entities/saved_place.dart';
import 'package:passenger/src/features/saved_places/domain/repositories/saved_places_repository.dart';
import 'package:passenger/src/features/saved_places/domain/saved_place_defaults.dart';
import 'package:passenger/src/features/saved_places/presentation/bloc/saved_places/saved_places_state.dart';

class SavedPlacesCubit({required this._repository})
    extends Cubit<SavedPlacesState> {
  final SavedPlacesRepository _repository;

  this : super(const SavedPlacesState());

  Future<void> loadPlaces() async {
    emit(state.copyWith(isLoading: true, clearErrorMessage: true));

    try {
      final rawPlaces = await _repository.loadPlaces();
      final parsedPlaces = rawPlaces
          .map((raw) => SavedPlaceModel.fromJson(raw))
          .toList();
      final places = normalizeSavedPlaceDefaults(parsedPlaces);
      String? repairErrorMessage;
      if (_needsDefaultRepair(parsedPlaces)) {
        try {
          await _repository.savePlaces(places);
        } catch (error, stackTrace) {
          repairErrorMessage = ErrorHandler.getErrorMessage(error, stackTrace);
        }
      }
      emit(
        SavedPlacesState(
          places: places,
          isLoading: false,
          errorMessage: repairErrorMessage,
          errorSource: repairErrorMessage == null
              ? null
              : SavedPlacesErrorSource.load,
        ),
      );
    } catch (error) {
      emit(
        SavedPlacesState(
          places: state.places,
          isLoading: false,
          errorMessage: ErrorHandler.getErrorMessage(error),
          errorSource: SavedPlacesErrorSource.load,
        ),
      );
    }
  }

  Future<void> addPlace(SavedPlace place) async {
    await _persistPlaces([...state.places, place]);
  }

  Future<void> removePlace(int index) async {
    if (index < 0 || index >= state.places.length) return;
    final updated = [...state.places]..removeAt(index);
    await _persistPlaces(updated);
  }

  Future<void> replacePlace(int index, SavedPlace place) async {
    if (index < 0 || index >= state.places.length) return;
    final replacement = place.copyWith(
      isDefault: place.isDefault || state.places[index].isDefault,
    );
    final updated = [...state.places]..[index] = replacement;
    await _persistPlaces(updated);
  }

  Future<void> setDefaultPlace(int index) async {
    if (index < 0 || index >= state.places.length) return;

    final updated = [
      for (var placeIndex = 0; placeIndex < state.places.length; placeIndex++)
        state.places[placeIndex].copyWith(isDefault: placeIndex == index),
    ];
    await _persistPlaces(updated);
  }

  Future<void> _persistPlaces(List<SavedPlace> places) async {
    final previous = state;
    final normalizedPlaces = normalizeSavedPlaceDefaults(places);
    emit(state.copyWith(places: normalizedPlaces, clearErrorMessage: true));
    try {
      await _repository.savePlaces(normalizedPlaces);
    } catch (error, stackTrace) {
      emit(
        previous.copyWith(
          errorMessage: ErrorHandler.getErrorMessage(error, stackTrace),
          errorSource: SavedPlacesErrorSource.persistence,
        ),
      );
    }
  }

  bool _needsDefaultRepair(List<SavedPlace> places) {
    if (places.isEmpty) return false;
    return places.where((place) => place.isDefault).length != 1;
  }
}
