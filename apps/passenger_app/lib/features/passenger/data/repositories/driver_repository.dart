/// Driver Repository implementation: manages driver discovery and ranks nearby drivers using real-time backend updates.
library;

import 'package:core_models/core_models.dart';
import 'package:location_service/location_service.dart';
import 'package:flutter/foundation.dart';
import 'package:passenger_app/core/services/passenger_api_service.dart';

class LocalDriverRepository implements DriverRepository {
  @override
  Future<List<DriverModel>> getNearbyDrivers({
    required double lat,
    required double lng,
  }) async {
    try {
      return DriverMatchingService.findNearbyDrivers(lat, lng);
    } catch (_) {
      return [];
    }
  }
}

class ApiDriverRepository implements DriverRepository {
  @override
  Future<List<DriverModel>> getNearbyDrivers({
    required double lat,
    required double lng,
  }) async {
    try {
      final rawList = await PassengerApiService.fetchOnlineDrivers();
      final List<DriverModel> drivers = [];
      for (final d in rawList) {
        final driverLat = (d['lat'] as num?)?.toDouble() ?? 0.0;
        final driverLng = (d['lng'] as num?)?.toDouble() ?? 0.0;
        final actualDist = MapNativeServiceImpl.calculateHaversine(
          lat,
          lng,
          driverLat,
          driverLng,
        );
        if (actualDist > 5.0) continue;
        final double etaMinutes = (actualDist / 20.0 * 60.0).clamp(1.0, 30.0);
        final rating = (d['rating'] as num?)?.toDouble() ?? 5.0;
        final double score = (0.5 * actualDist) + (0.3 * (5.0 - rating)) + (0.2 * etaMinutes);
        drivers.add(DriverModel(
          id: d['id'] as String? ?? '',
          name: d['name'] as String? ?? 'Driver',
          vehicleType: d['vehicleType'] as String? ?? 'Bao Bao',
          plateNumber: d['plateNumber'] as String? ?? 'Unknown',
          rating: rating,
          lat: driverLat,
          lng: driverLng,
          distanceKm: actualDist,
          etaMinutes: etaMinutes,
          score: score,
        ));
      }
      drivers.sort((a, b) => a.score.compareTo(b.score));
      return drivers.take(5).toList();
    } catch (e) {
      debugPrint('ApiDriverRepository.getNearbyDrivers failed: $e');
      return [];
    }
  }
}
