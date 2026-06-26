import 'package:passenger_app/features/passenger/presentation/views/home/models/saved_place_model.dart';

/**
 * Abstract contract for persisting and retrieving the passenger's saved-place
 * shortcut chips across app sessions.
 *
 * Implementations decouple the presentation layer from the underlying storage
 * mechanism (SharedPreferences, Hive, remote API). The cubit depends only on
 * this interface, allowing the concrete backing store to be swapped without
 * touching any UI or state-management code.
 */
abstract class SavedPlacesRepository {
  /**
   * Loads all saved places from persistent storage.
   * Returns the default three seeds (Home, Campus, Work) on first run
   * when no persisted data exists yet.
   */
  Future<List<Map<String, dynamic>>> loadPlaces();

  /**
   * Persists the full updated list of saved places to storage, replacing any
   * previously stored snapshot. Called after every add or remove operation.
   */
  Future<void> savePlaces(List<SavedPlaceModel> places);
}
