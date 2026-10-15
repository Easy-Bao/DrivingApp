import 'package:passenger/src/features/saved_places/domain/entities/saved_place.dart';

/// Returns a copy of [places] with exactly one default when it is non-empty.
///
/// Existing order is preserved. If stored data has no default or several
/// defaults, the first place wins so legacy data is repaired deterministically.
List<SavedPlace> normalizeSavedPlaceDefaults(Iterable<SavedPlace> places) {
  final savedPlaces = places.toList(growable: false);
  if (savedPlaces.isEmpty) return const [];

  final explicitDefaultIndex = savedPlaces.indexWhere(
    (place) => place.isDefault,
  );
  final defaultIndex = explicitDefaultIndex == -1 ? 0 : explicitDefaultIndex;

  return List<SavedPlace>.unmodifiable([
    for (var index = 0; index < savedPlaces.length; index++)
      savedPlaces[index].copyWith(isDefault: index == defaultIndex),
  ]);
}

int defaultSavedPlaceIndex(List<SavedPlace> places) {
  if (places.isEmpty) return -1;
  final explicitDefaultIndex = places.indexWhere((place) => place.isDefault);
  return explicitDefaultIndex == -1 ? 0 : explicitDefaultIndex;
}

SavedPlace? defaultSavedPlace(List<SavedPlace> places) {
  final index = defaultSavedPlaceIndex(places);
  return index == -1 ? null : places[index];
}
