import 'package:location_service/location_service.dart';
import 'package:core_models/core_models.dart';
import 'package:fixtures/fixtures.dart';
import 'package:flutter/foundation.dart';

/**
 * Geocoding and history synchronization adapter.
 *
 * This repository implements [PassengerHomeRepository] by routing reverse-geocoding
 * queries through [MapProvider.getPlaceFromCoordinates], which invokes Mapbox API.
 *
 * **Lifecycle & Execution Flow:**
 * Address resolution begins when the presentation layer (via BLoC) requests the descriptive
 * location name for a specific coordinate pair. The repository delegates this query by
 * calling [resolveAddress], which asynchronously invokes the Mapbox Reverse Geocoding API.
 * When the execution completes successfully, the returned location string is supplied back
 * to the caller. If the call encounters a failure, timeout, or returns an empty result, the
 * repository intercepts the exception, logs it, and returns the fallback address
 * "Pagadian City, Zamboanga del Sur" to ensure the user interface remains functional.
 *
 * **State & Concurrency:**
 * All service calls execute asynchronously, preventing blocking of the UI thread.
 */
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
    // Mimics reading recent activity records from local storage.
    await Future.delayed(const Duration(milliseconds: 150));
    return MockData.getRecentLocations();
  }
}
