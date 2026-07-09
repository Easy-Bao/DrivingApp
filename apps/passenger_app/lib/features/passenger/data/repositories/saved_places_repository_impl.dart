import 'dart:convert';

import 'package:passenger_app/features/passenger/data/repositories/saved_places_repository.dart';
import 'package:passenger_app/features/passenger/presentation/views/home/models/saved_place_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/**
 * SharedPreferences-backed implementation of [SavedPlacesRepository].
 *
 * Lifecycle and persistence strategy:
 * On first launch (no key present), [loadPlaces] seeds three default shortcuts
 * (Home, Campus, Work) without pinned coordinates. These defaults signal to the
 * presentation layer that tapping them should open SearchDestination rather than
 * DestinationPreview, since no coordinate is yet associated.
 *
 * On subsequent launches, the JSON array previously written by [savePlaces] is
 * decoded and returned as a list of raw maps. The [onTap] callbacks are not
 * stored because Dart callbacks are non-serialisable; they are injected by the
 * cubit after decoding based on each entry's coordinates.
 *
 * Storage key: [_storageKey] — a versioned constant so future schema migrations
 * can bump the version suffix without reading stale data.
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

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .cast<Map<String, dynamic>>()
        .toList();
  }

  @override
  Future<void> savePlaces(List<SavedPlaceModel> places) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, SavedPlaceModel.encodeList(places));
  }
}
