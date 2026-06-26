import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/features/passenger/data/repositories/saved_places_repository.dart';
import 'package:passenger_app/features/passenger/presentation/bloc/home/saved_places_state.dart';
import 'package:passenger_app/features/passenger/presentation/views/home/models/saved_place_model.dart';

/**
 * Cubit that owns the lifecycle of the passenger's saved-place shortcut chips.
 *
 * On construction the cubit is inert. [loadPlaces] must be called once (from
 * the widget's initState or a PostFrameCallback) to hydrate the state from
 * the [SavedPlacesRepository]. After that, [addPlace] and [removePlace] keep
 * the in-memory state and the persisted snapshot in sync atomically.
 *
 * Navigation callbacks ([onTap]) are injected here rather than in the
 * repository because they require a live [BuildContext] from the widget tree.
 * The cubit holds the [BuildContext] as a nullable field, set by the
 * presentation layer after the widget mounts. This is an established pattern
 * when a cubit must emit navigation side-effects.
 */
class SavedPlacesCubit extends Cubit<SavedPlacesState> {
  final SavedPlacesRepository _repository;

  /**
   * Navigation context injected by the home screen after widget mount.
   * Required to build the [onTap] callbacks for each chip.
   */
  BuildContext? _context;

  SavedPlacesCubit({required SavedPlacesRepository repository})
      : _repository = repository,
        super(const SavedPlacesState());

  /** Provides the widget context needed for navigation callbacks. */
  void attachContext(BuildContext context) {
    _context = context;
  }

  /**
   * Loads saved places from storage and hydrates state.
   * Each raw JSON map is converted to a [SavedPlaceModel] with an [onTap]
   * callback wired to the appropriate navigation destination.
   */
  Future<void> loadPlaces() async {
    emit(state.copyWith(isLoading: true));

    try {
      final rawPlaces = await _repository.loadPlaces();
      final models = rawPlaces.map((raw) => _buildModel(raw)).toList();
      emit(SavedPlacesState(places: models, isLoading: false));
    } catch (e, stack) {
      debugPrint('Error loading saved places: $e\n$stack');
      emit(SavedPlacesState(places: const [], isLoading: false));
    }
  }

  /**
   * Appends a new saved place and persists the updated list.
   * The [onTap] callback is rebuilt from the model's coordinates so the
   * navigation destination reflects the newly pinned location.
   */
  Future<void> addPlace(SavedPlaceModel place) async {
    final wired = place.copyWith(onTap: _buildOnTap(place));
    final updated = [...state.places, wired];
    emit(state.copyWith(places: updated));
    await _repository.savePlaces(updated);
  }

  /**
   * Removes the chip at [index] and persists the updated list.
   */
  Future<void> removePlace(int index) async {
    final updated = [...state.places]..removeAt(index);
    emit(state.copyWith(places: updated));
    await _repository.savePlaces(updated);
  }

  /**
   * Constructs a [SavedPlaceModel] from a raw JSON map, injecting the
   * appropriate [onTap] navigation callback based on whether coordinates exist.
   */
  SavedPlaceModel _buildModel(Map<String, dynamic> raw) {
    final place = SavedPlaceModel.fromJson(raw, () {});
    return place.copyWith(onTap: _buildOnTap(place));
  }

  /**
   * Builds the navigation callback for a saved place chip.
   *
   * When coordinates are present the chip routes directly to DestinationPreview
   * with a synthesised PlaceModel, bypassing the search flow entirely. When
   * coordinates are absent (default seeds without a pinned location) the chip
   * opens SearchDestination so the passenger can pick a destination normally.
   */
  VoidCallback _buildOnTap(SavedPlaceModel place) {
    return () {
      final ctx = _context;
      if (ctx == null || !ctx.mounted) return;

      if (place.hasLocation) {
        final syntheticPlace = PlaceModel(
          id: 'saved_${place.label.toLowerCase().replaceAll(' ', '_')}',
          name: place.label,
          fullAddress: place.savedAddress ?? place.label,
          latitude: place.latitude!,
          longitude: place.longitude!,
        );
        ctx.pushNamed('DestinationPreview', extra: syntheticPlace);
      } else {
        ctx.pushNamed('SearchDestination');
      }
    };
  }

  /** Maps an [iconName] string to a Lucide IconData for chip rendering. */
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
