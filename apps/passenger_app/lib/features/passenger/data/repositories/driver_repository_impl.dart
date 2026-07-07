/// Driver Repository implementation: manages driver discovery and ranks nearby drivers using real-time backend updates.
import 'package:core_models/core_models.dart';
import 'package:location_service/location_service.dart';
import 'package:flutter/foundation.dart';
import 'package:passenger_app/core/services/passenger_api_service.dart';

class DriverRepositoryImpl implements DriverRepository {
  @override
  Future<List<DriverModel>> getNearbyDrivers({
    required double lat,
    required double lng,
  }) async {
    try {
      final rawList = await PassengerApiService.fetchOnlineDrivers();
      return _processNearbyDrivers(rawList, lat, lng);
    } catch (e) {
      debugPrint('DriverRepositoryImpl.getNearbyDrivers failed: $e');
      return [];
    }
  }

  List<DriverModel> _processNearbyDrivers(List<dynamic> rawDrivers, double userLat, double userLng) {
    final List<DriverModel> drivers = [];
    for (final d in rawDrivers) {
      if (d is! Map<String, dynamic>) continue;
      final driverLat = (d['lat'] as num?)?.toDouble() ?? 0.0;
      final driverLng = (d['lng'] as num?)?.toDouble() ?? 0.0;
      
      final distanceKm = _calculateDistance(userLat, userLng, driverLat, driverLng);
      if (distanceKm > 5.0) continue;
      
      final etaMinutes = _calculateEta(distanceKm);
      final rating = (d['rating'] as num?)?.toDouble() ?? 5.0;
      final score = _calculateMatchingScore(distanceKm, rating, etaMinutes);
      
      drivers.add(_mapToDriverModel(d, distanceKm, etaMinutes, score));
    }
    
    drivers.sort((a, b) => a.score.compareTo(b.score));
    return drivers.take(5).toList();
  }

  double _calculateDistance(double userLat, double userLng, double driverLat, double driverLng) {
    return MapNativeServiceImpl.calculateHaversine(
      userLat,
      userLng,
      driverLat,
      driverLng,
    );
  }

  double _calculateEta(double distanceKm) {
    return (distanceKm / 20.0 * 60.0).clamp(1.0, 30.0);
  }

  double _calculateMatchingScore(double distanceKm, double rating, double etaMinutes) {
    // Score formula: 50% distance, 30% rating gap, 20% ETA
    return (0.5 * distanceKm) + (0.3 * (5.0 - rating)) + (0.2 * etaMinutes);
  }

  DriverModel _mapToDriverModel(
    Map<String, dynamic> data,
    double distanceKm,
    double etaMinutes,
    double score,
  ) {
    return DriverModel(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? 'Driver',
      vehicleType: data['vehicleType'] as String? ?? 'Bao Bao',
      plateNumber: data['plateNumber'] as String? ?? 'Unknown',
      rating: (data['rating'] as num?)?.toDouble() ?? 5.0,
      lat: (data['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (data['lng'] as num?)?.toDouble() ?? 0.0,
      distanceKm: distanceKm,
      etaMinutes: etaMinutes,
      score: score,
    );
  }
}
