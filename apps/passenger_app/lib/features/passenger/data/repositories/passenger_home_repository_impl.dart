/// Geocoding and history synchronization adapter: fetches recent locations and resolves coordinates dynamically.
import 'package:location_service/location_service.dart';
import 'package:core_models/core_models.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:passenger_app/core/services/passenger_api_service.dart';

/// Shortens a full address to its last two comma-separated segments (e.g. "Barangay, City").
String _shortenAddress(String fullAddress) {
  final parts = fullAddress.split(',').map((p) => p.trim()).toList();
  if (parts.length >= 2) {
    return '${parts[parts.length - 2]}, ${parts.last}';
  }
  return fullAddress;
}

class PassengerHomeRepositoryImpl implements PassengerHomeRepository {
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
    } catch (error) {
      debugPrint('PassengerHomeRepositoryImpl.resolveAddress failed: $error');
      return '';
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getRecentLocations() async {
    try {
      final passengerId = await _getPassengerId();
      if (passengerId.isEmpty) {
        return [];
      }
      final rawRides = await PassengerApiService.fetchRideHistory(passengerId);
      return _filterAndFormatRecentLocations(rawRides);
    } catch (error) {
      debugPrint('PassengerHomeRepositoryImpl.getRecentLocations failed: $error');
      return [];
    }
  }

  Future<String> _getPassengerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('passenger_id') ?? '';
  }

  List<Map<String, dynamic>> _filterAndFormatRecentLocations(List<dynamic> rawRides) {
    final Set<String> seenDestinations = {};
    final List<Map<String, dynamic>> list = [];
    for (final r in rawRides) {
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
  }
}
