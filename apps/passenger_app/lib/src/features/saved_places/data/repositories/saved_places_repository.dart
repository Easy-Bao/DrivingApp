import 'dart:convert';

import 'package:passenger_app/src/features/saved_places/data/models/saved_place_model.dart';
import 'package:passenger_app/src/features/saved_places/domain/entities/saved_place.dart';
import 'package:passenger_app/src/features/saved_places/domain/repositories/i_saved_places_repository.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedPlacesRepository implements ISavedPlacesRepository {
  static const String _storageKey = 'passenger_saved_places_v1';

  @override
  Future<List<Map<String, dynamic>>> loadPlaces() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.trim().isEmpty) {
        return const [];
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) {
        await prefs.remove(_storageKey);
        return const [];
      }

      final places = <Map<String, dynamic>>[];
      for (final item in decoded) {
        if (item is! Map) {
          await prefs.remove(_storageKey);
          return const [];
        }
        places.add(Map<String, dynamic>.from(item));
      }
      return places;
    } catch (error) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      return const [];
    }
  }

  @override
  Future<void> savePlaces(List<SavedPlace> places) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final models = places
          .map(
            (p) => SavedPlaceModel(
              label: p.label,
              iconName: p.iconName,
              savedAddress: p.savedAddress,
              latitude: p.latitude,
              longitude: p.longitude,
              isDefault: p.isDefault,
            ),
          )
          .toList();
      await prefs.setString(_storageKey, SavedPlaceModel.encodeList(models));
    } catch (error) {
      throw const CacheFailure('Failed to write saved places to storage.');
    }
  }
}
