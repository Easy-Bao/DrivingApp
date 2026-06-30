/// Geocoding and history synchronization adapter: fetches recent locations and resolves coordinates dynamically.
import 'package:location_service/location_service.dart';
import 'package:core_models/core_models.dart';
import 'package:fixtures/fixtures.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:passenger_app/core/services/passenger_api_service.dart';

class LocalPassengerHomeRepository implements PassengerHomeRepository {
  @override
  Future<String> resolveAddress({
    required double lat,
    required double lng,
  }) async {
    try {
      final place = await MapProvider.getPlaceFromCoordinates(lat, lng);
      if (place != null && place.fullAddress.isNotEmpty) {
        return place.fullAddress;
      }
      return MockData.defaultAddress;
    } catch (e) {
      debugPrint('LocalPassengerHomeRepository.resolveAddress failed: $e');
      return MockData.defaultAddress;
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
      for (final r in rawRides) {
        final destName = r['dropoff_name'] as String;
        if (!seenDestinations.contains(destName)) {
          seenDestinations.add(destName);
          list.add({
            'title': destName,
            'subtitle': r['pickup_name'] as String? ?? 'Previous Trip',
            'lat': (r['dropoff_latitude'] as num).toDouble(),
            'lng': (r['dropoff_longitude'] as num).toDouble(),
          });
        }
        if (list.length >= 5) break;
      }
      return list;
    } catch (e) {
      debugPrint('LocalPassengerHomeRepository.getRecentLocations failed: $e');
      return [];
    }
  }
}
