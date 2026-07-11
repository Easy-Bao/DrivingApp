import 'package:passenger_app/src/features/trip_booking/domain/entities/saved_place.dart';

/**
 * Abstract contract for persisting and retrieving the passenger's saved-place
 * shortcut chips across app sessions.
 */
abstract class SavedPlacesRepository {
  /** Loads all saved places from persistent storage. */
  Future<List<Map<String, dynamic>>> loadPlaces();

  /** Persists the full list of saved places to local storage. */
  Future<void> savePlaces(List<SavedPlace> places);
}
