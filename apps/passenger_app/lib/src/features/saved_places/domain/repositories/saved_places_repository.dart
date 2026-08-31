import 'package:passenger_app/src/features/saved_places/domain/entities/saved_place.dart';

abstract interface class SavedPlacesRepository {
  Future<List<Map<String, dynamic>>> loadPlaces();

  Future<void> savePlaces(List<SavedPlace> places);
}
