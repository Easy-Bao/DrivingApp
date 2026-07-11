import 'dart:convert';
import 'package:passenger_app/src/features/trip_booking/data/models/saved_place_model.dart';
import 'package:passenger_app/src/features/trip_booking/domain/entities/saved_place.dart';
import 'package:passenger_app/src/features/trip_booking/domain/repositories/saved_places_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/**
 * SharedPreferences-backed implementation of [SavedPlacesRepository].
 *
 * Seeds three default shortcuts (Home, Campus, Work) on the first run,
 * and encodes/decodes list objects as JSON for simple storage persistence.
 */
class SavedPlacesRepositoryImpl implements SavedPlacesRepository {
  static const String _storageKey = 'passenger_saved_places_v1';

  @override
  Future<List<Map<String, dynamic>>> loadPlaces() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null) {
      return SavedPlaceModel.defaults
          .map((d) => Map<String, dynamic>.from(d))
          .toList();
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>().toList();
    } catch (error) {
      // Re-seed defaults if storage format is corrupt
      return SavedPlaceModel.defaults
          .map((d) => Map<String, dynamic>.from(d))
          .toList();
    }
  }

  @override
  Future<void> savePlaces(List<SavedPlace> places) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final models = places.map((p) => SavedPlaceModel(
        label: p.label,
        iconName: p.iconName,
        savedAddress: p.savedAddress,
        latitude: p.latitude,
        longitude: p.longitude,
      )).toList();
      await prefs.setString(_storageKey, SavedPlaceModel.encodeList(models));
    } catch (error) {
      // Ensure we fail cleanly on write error
      throw Exception('Failed to write saved places to storage: $error');
    }
  }
}
