import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:passenger_app/src/features/trip_booking/data/models/saved_place_model.dart';
import 'package:passenger_app/src/features/trip_booking/domain/entities/saved_place.dart';
import 'package:passenger_app/src/features/trip_booking/domain/repositories/saved_places_repository.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/blocs/home/saved_places_state.dart';

/// Cubit managing passenger saved place shortcut chips.
/// Entirely decoupled from BuildContext and UI navigation.
class SavedPlacesCubit extends Cubit<SavedPlacesState> {
  final SavedPlacesRepository _repository;

  SavedPlacesCubit({required SavedPlacesRepository repository})
    : _repository = repository,
      super(const SavedPlacesState());

  /// Loads all pinned shortcuts from local storage.
  Future<void> loadPlaces() async {
    emit(state.copyWith(isLoading: true));

    try {
      final rawPlaces = await _repository.loadPlaces();
      final models = rawPlaces
          .map((raw) => SavedPlaceModel.fromJson(raw))
          .toList();
      emit(SavedPlacesState(places: models, isLoading: false));
    } catch (error, stackTrace) {
      debugPrint('Error loading saved places in cubit: $error\n$stackTrace');
      emit(const SavedPlacesState(places: [], isLoading: false));
    }
  }

  /// Adds a new pinned shortcut and updates storage.
  Future<void> addPlace(SavedPlace place) async {
    final updated = [...state.places, place];
    emit(state.copyWith(places: updated));
    try {
      await _repository.savePlaces(updated);
    } catch (error) {
      debugPrint('Error saving places in cubit: $error');
    }
  }

  /// Removes a pinned shortcut at [index] and updates storage.
  Future<void> removePlace(int index) async {
    if (index < 0 || index >= state.places.length) return;
    final updated = [...state.places]..removeAt(index);
    emit(state.copyWith(places: updated));
    try {
      await _repository.savePlaces(updated);
    } catch (error) {
      debugPrint('Error saving places after deletion: $error');
    }
  }

  /// Helper utility mapping a dynamic icon name back to its respective [IconData].
  static IconData iconFromName(String iconName) {
    switch (iconName) {
      case 'house':
        return LucideIcons.house;
      case 'graduation_cap':
        return LucideIcons.graduation_cap;
      case 'briefcase':
        return LucideIcons.briefcase;
      case 'map_pin':
        return LucideIcons.map_pin;
      case 'heart':
        return LucideIcons.heart;
      case 'star':
        return LucideIcons.star;
      case 'coffee':
        return LucideIcons.coffee;
      case 'dumbbell':
        return LucideIcons.dumbbell;
      case 'shopping_cart':
        return LucideIcons.shopping_cart;
      default:
        return LucideIcons.map_pin;
    }
  }
}
