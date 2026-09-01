import 'package:foundation/foundation.dart';
import 'package:maps/maps.dart';

final RegExp _nonAlphanumericSearchPattern = RegExp(r'[^a-z0-9]+');
const double _coordinateDuplicateTolerance = 0.0001;

String destinationPlaceKey(Place place) {
  return '${place.id}:${place.latitude.toStringAsFixed(5)}:${place.longitude.toStringAsFixed(5)}';
}

String destinationNameKey(Place place) {
  return place.name.toLowerCase().replaceAll(_nonAlphanumericSearchPattern, '');
}

List<Place> mergeUniqueDestinationResults(
  Iterable<Place> existing,
  Iterable<Place> incoming, {
  bool compareCoordinates = false,
}) {
  final merged = existing.toList();
  final knownNames = merged.map(destinationNameKey).toSet();
  final coordinateBuckets = <(int, int), List<Place>>{};

  if (compareCoordinates) {
    for (final place in merged) {
      _indexDestinationCoordinate(coordinateBuckets, place);
    }
  }

  for (final place in incoming) {
    final nameKey = destinationNameKey(place);
    if (knownNames.contains(nameKey) ||
        compareCoordinates &&
            _hasMatchingDestinationCoordinate(coordinateBuckets, place)) {
      continue;
    }
    merged.add(place);
    knownNames.add(nameKey);
    if (compareCoordinates) {
      _indexDestinationCoordinate(coordinateBuckets, place);
    }
  }

  return merged;
}

bool destinationMatchesSearchQuery(Place place, String query) {
  final normalizedQuery = _normalizeSearchText(query);
  if (normalizedQuery.isEmpty) return false;

  final searchableText = _normalizeSearchText(
    '${place.name} ${place.fullAddress}',
  );
  final compactQuery = _compactSearchText(query);
  final compactSearchableText = _compactSearchText(
    '${place.name} ${place.fullAddress}',
  );
  if (compactQuery.isNotEmpty && compactSearchableText.contains(compactQuery)) {
    return true;
  }
  if (searchableText.contains(normalizedQuery)) return true;

  final queryTokens = normalizedQuery.split(' ');
  final searchableTokens = searchableText.split(' ');
  return queryTokens.every(
    (queryToken) => searchableTokens.any(
      (searchableToken) => searchableToken.startsWith(queryToken),
    ),
  );
}

List<Place> sortDestinationsByDistance(
  List<Place> places,
  Map<String, double> drivingDistances,
) {
  final sorted = [...places];
  sorted.sort(
    (a, b) => _distanceForSorting(
      a,
      drivingDistances,
    ).compareTo(_distanceForSorting(b, drivingDistances)),
  );
  return sorted;
}

String formatDestinationDistance(double distanceKm) {
  if (distanceKm < 0.1) {
    return '${(distanceKm * 1000).round()} m away';
  }
  return '${DistanceFormatter.fromKilometers(distanceKm)} away';
}

String formatDestinationPlaceDistance(
  Place place,
  Map<String, double> drivingDistances,
  Set<String> drivingDistanceRequests,
) {
  final key = destinationPlaceKey(place);
  final drivingDistance = drivingDistances[key];
  if (drivingDistance != null) {
    return formatDestinationDistance(drivingDistance);
  }
  if (drivingDistanceRequests.contains(key)) {
    return 'Calculating route...';
  }
  return place.distanceKm != null
      ? formatDestinationDistance(place.distanceKm!)
      : place.category ?? 'Nearby POI';
}

String _normalizeSearchText(String value) {
  return value
      .toLowerCase()
      .replaceAll(_nonAlphanumericSearchPattern, ' ')
      .trim();
}

String _compactSearchText(String value) {
  return _normalizeSearchText(value).replaceAll(' ', '');
}

double _distanceForSorting(Place place, Map<String, double> drivingDistances) {
  return drivingDistances[destinationPlaceKey(place)] ??
      place.distanceKm ??
      double.maxFinite;
}

(int, int) _destinationCoordinateBucket(Place place) {
  return (
    (place.latitude / _coordinateDuplicateTolerance).floor(),
    (place.longitude / _coordinateDuplicateTolerance).floor(),
  );
}

void _indexDestinationCoordinate(
  Map<(int, int), List<Place>> buckets,
  Place place,
) {
  (buckets[_destinationCoordinateBucket(place)] ??= []).add(place);
}

bool _hasMatchingDestinationCoordinate(
  Map<(int, int), List<Place>> buckets,
  Place candidate,
) {
  final (latitudeBucket, longitudeBucket) = _destinationCoordinateBucket(
    candidate,
  );
  for (var latitudeOffset = -1; latitudeOffset <= 1; latitudeOffset++) {
    for (var longitudeOffset = -1; longitudeOffset <= 1; longitudeOffset++) {
      final nearbyPlaces =
          buckets[(
            latitudeBucket + latitudeOffset,
            longitudeBucket + longitudeOffset,
          )];
      if (nearbyPlaces == null) continue;
      if (nearbyPlaces.any(
        (place) =>
            (place.latitude - candidate.latitude).abs() <
                _coordinateDuplicateTolerance &&
            (place.longitude - candidate.longitude).abs() <
                _coordinateDuplicateTolerance,
      )) {
        return true;
      }
    }
  }
  return false;
}
