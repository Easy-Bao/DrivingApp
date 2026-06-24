import 'package:passenger_app/core/services/map_provider.dart';
import 'package:passenger_app/features/passenger/data/repositories/passenger_home_repository.dart';
import 'package:fixtures/fixtures.dart';
import 'package:flutter/foundation.dart';


/**
 * Rust-backed geocoding and history synchronization adapter.
 *
 * This repository implements [PassengerHomeRepository] by routing reverse-geocoding
 * queries through [MapProvider.getPlaceFromCoordinates], which in turn invokes
 * the native Rust library compiled via `flutter_rust_bridge`. 
 *
 * **Lifecycle & Execution Flow:**
 * Address resolution begins when the presentation layer (via BLoC) requests the descriptive
 * location name for a specific coordinate pair. The repository delegates this query by
 * calling [resolveAddress], which asynchronously invokes the Mapbox Reverse Geocoding API
 * wrapper compiled in the Rust layer. When the Rust execution completes successfully, the
 * returned location string is supplied back to the caller. If the FFI call encounters a
 * transport failure, timeout, or returns an empty result, the repository intercepts the
 * exception, logs it, and returns the fallback address "Pagadian City, Zamboanga del Sur"
 * to ensure the user interface remains fully functional.
 *
 * **State & Concurrency:**
 * All bridge calls execute asynchronously in Rust's background threads, preventing
 * blocking of the Dart isolate or UI rendering pipeline.
 */
class RustPassengerHomeRepository implements PassengerHomeRepository {
  
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
      debugPrint('RustPassengerHomeRepository.resolveAddress failed: $e');
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
