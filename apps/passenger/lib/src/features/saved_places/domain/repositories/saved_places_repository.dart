import 'package:passenger/src/features/saved_places/domain/entities/saved_place.dart';

abstract interface class SavedPlacesRepository {
  Future<List<SavedPlace>> loadPlaces();

  Future<void> savePlaces(List<SavedPlace> places);
}
