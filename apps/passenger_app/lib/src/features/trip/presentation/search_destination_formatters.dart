import 'package:shared_core/shared_core.dart';
import 'package:maps/maps.dart';

String destinationPlaceKey(Place place) {
  return '${place.id}:${place.latitude.toStringAsFixed(5)}:${place.longitude.toStringAsFixed(5)}';
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
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
}

String _compactSearchText(String value) {
  return _normalizeSearchText(value).replaceAll(' ', '');
}

double _distanceForSorting(Place place, Map<String, double> drivingDistances) {
  return drivingDistances[destinationPlaceKey(place)] ??
      place.distanceKm ??
      double.maxFinite;
}
