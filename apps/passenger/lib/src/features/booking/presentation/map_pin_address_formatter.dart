import 'package:maps/maps.dart';

const _cityKeys = ['city', 'place', 'municipality', 'town'];
const _barangayKeys = [
  'barangay',
  'locality',
  'neighborhood',
  'village',
  'district',
];
const _areaFallbackKeys = ['province', 'region', 'county'];

String formatMapPinSubtitle(Place? place) {
  if (place == null) return '';

  final city = _firstContextValue(place.context, _cityKeys);
  final barangay = _firstContextValue(place.context, _barangayKeys);
  final areaFallback = _firstContextValue(place.context, _areaFallbackKeys);
  final contextParts = <String>[];
  _appendUnique(contextParts, city);
  _appendUnique(contextParts, barangay ?? areaFallback);
  if (contextParts.length >= 2) return contextParts.join(', ');

  final addressParts = place.fullAddress
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();
  final placeNames = {
    place.name.trim().toLowerCase(),
    place.displayName.trim().toLowerCase(),
  };
  final areaParts = addressParts
      .where((part) => !placeNames.contains(part.toLowerCase()))
      .toList();
  if (areaParts.length > 2) {
    return areaParts.sublist(areaParts.length - 2).join(', ');
  }
  return areaParts.join(', ');
}

String? _firstContextValue(Map<String, String> context, List<String> keys) {
  for (final key in keys) {
    final value = context[key]?.trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return null;
}

void _appendUnique(List<String> values, String? value) {
  if (value == null || value.isEmpty) return;
  if (values.any((item) => item.toLowerCase() == value.toLowerCase())) return;
  values.add(value);
}
