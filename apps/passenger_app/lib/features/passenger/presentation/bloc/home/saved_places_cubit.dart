import 'dart:async';

import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/features/passenger/data/repositories/saved_places_repository.dart';
import 'package:passenger_app/features/passenger/presentation/bloc/home/passenger_home_cubit.dart';
import 'package:passenger_app/features/passenger/presentation/bloc/home/saved_places_state.dart';
import 'package:passenger_app/features/passenger/presentation/views/home/models/saved_place_model.dart';

class SavedPlacesCubit extends Cubit<SavedPlacesState> {
  final SavedPlacesRepository _repository;
  BuildContext? _context;

  SavedPlacesCubit({required SavedPlacesRepository repository})
      : _repository = repository,
        super(const SavedPlacesState());

  // ignore: use_setters_to_change_properties
  void attachContext(BuildContext context) {
    _context = context;
  }

  Future<void> loadPlaces() async {
    emit(state.copyWith(isLoading: true));

    try {
      final rawPlaces = await _repository.loadPlaces();
      final models = rawPlaces.map((raw) => _buildModel(raw)).toList();
      emit(SavedPlacesState(places: models, isLoading: false));
    } catch (error, stackTrace) {
      debugPrint('Error loading saved places: $error\n$stackTrace');
      emit(const SavedPlacesState(places: [], isLoading: false));
    }
  }

  Future<void> addPlace(SavedPlaceModel place) async {
    final wired = place.copyWith(onTap: _buildOnTap(place));
    final updated = [...state.places, wired];
    emit(state.copyWith(places: updated));
    await _repository.savePlaces(updated);
  }

  Future<void> removePlace(int index) async {
    final updated = [...state.places]..removeAt(index);
    emit(state.copyWith(places: updated));
    await _repository.savePlaces(updated);
  }

  SavedPlaceModel _buildModel(Map<String, dynamic> raw) {
    final place = SavedPlaceModel.fromJson(raw, () {});
    return place.copyWith(onTap: _buildOnTap(place));
  }

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
        final address = BlocProvider.of<PassengerHomeCubit>(ctx).state.currentAddress;
        unawaited(
          ctx.pushNamed(
            'DestinationPreview',
            extra: syntheticPlace,
            queryParameters: {'pickupAddress': address},
          ),
        );
      } else {
        final address = BlocProvider.of<PassengerHomeCubit>(ctx).state.currentAddress;
        unawaited(
          ctx.pushNamed(
            'SearchDestination',
            queryParameters: {'pickupAddress': address},
          ),
        );
      }
    };
  }

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
