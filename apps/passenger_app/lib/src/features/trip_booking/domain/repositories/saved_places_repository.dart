import 'package:passenger_app/src/features/trip_booking/domain/entities/saved_place.dart';

/// Repository contract for persisting and retrieving the passenger's saved-place
/// shortcut chips (e.g., Home, Work) across app sessions.
abstract class SavedPlacesRepository {
  /// Loads all saved places from persistent storage.
  ///
  /// Returns a list of raw maps representing the saved places.
  Future<List<Map<String, dynamic>>> loadPlaces();

  /// Persists the full list of [places] to local storage.
  Future<void> savePlaces(List<SavedPlace> places);
}
