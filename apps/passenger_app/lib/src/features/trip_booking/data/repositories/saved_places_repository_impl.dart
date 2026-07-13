import 'dart:convert';
import 'package:core_models/core_models.dart';
import 'package:passenger_app/src/features/trip_booking/data/models/saved_place_model.dart';
import 'package:passenger_app/src/features/trip_booking/domain/entities/saved_place.dart';
import 'package:passenger_app/src/features/trip_booking/domain/repositories/saved_places_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedPlacesRepositoryImpl implements SavedPlacesRepository {
  static const String _storageKey = 'passenger_saved_places_v1';

  @override
  Future<List<Map<String, dynamic>>> loadPlaces() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);

      if (raw == null) {
        return SavedPlaceModel.defaults
            .map((d) => Map<String, dynamic>.from(d))
            .toList();
      }

      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>().toList();
    } catch (error) {
      throw const CacheFailure('Failed to load saved places from cache.');
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
            ),
          )
          .toList();
      await prefs.setString(_storageKey, SavedPlaceModel.encodeList(models));
    } catch (error) {
      throw const CacheFailure('Failed to write saved places to storage.');
    }
  }
}
