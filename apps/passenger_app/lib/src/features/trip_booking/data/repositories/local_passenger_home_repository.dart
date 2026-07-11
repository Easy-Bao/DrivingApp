import 'package:core_models/core_models.dart';
import 'package:flutter/foundation.dart';
import 'package:location_service/location_service.dart';
import 'package:passenger_app/src/core/services/passenger_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _shortenAddress(String fullAddress) {
  final parts = fullAddress.split(',').map((p) => p.trim()).toList();
  if (parts.length >= 2) {
    return '${parts[parts.length - 2]}, ${parts.last}';
  }
  return fullAddress;
}

class LocalPassengerHomeRepository implements PassengerHomeRepository {
  @override
  Future<String> resolveAddress({
    required double lat,
    required double lng,
  }) async {
    try {
      final place = await MapProvider.getPlaceFromCoordinates(lat, lng);
      if (place != null && place.fullAddress.isNotEmpty) {
        return _shortenAddress(place.fullAddress);
      }
      return '';
    } catch (e) {
      debugPrint('LocalPassengerHomeRepository.resolveAddress failed: $e');
      return '';
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getRecentLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final passengerId = prefs.getString('passenger_id') ?? '';
      if (passengerId.isEmpty) {
        return [];
      }
      final rawRides = await PassengerApiService.fetchRideHistory(passengerId);
      final Set<String> seenDestinations = {};
      final List<Map<String, dynamic>> list = [];
      for (final r in rawRides.cast<Map<String, dynamic>>()) {
        final status = r['status'] as String? ?? '';
        if (status != 'completed') continue;
        final destName = r['dropoff_name'] as String? ?? '';
        if (destName.isEmpty || seenDestinations.contains(destName)) continue;
        seenDestinations.add(destName);
        final pickupName = r['pickup_name'] as String? ?? 'Previous Trip';
        list.add({
          'title': _shortenAddress(destName),
          'subtitle': _shortenAddress(pickupName),
          'lat': (r['dropoff_latitude'] as num).toDouble(),
          'lng': (r['dropoff_longitude'] as num).toDouble(),
        });
        if (list.length >= 5) break;
      }
      return list;
    } catch (e) {
      debugPrint('LocalPassengerHomeRepository.getRecentLocations failed: $e');
      return [];
    }
  }
}
