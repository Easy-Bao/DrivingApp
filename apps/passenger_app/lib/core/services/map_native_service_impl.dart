import 'package:core_models/core_models.dart';
import 'package:location_service/location_service.dart';
import 'package:passenger_app/src/rust/api/map_api.dart' as rust_api;

/**
 * Concrete implementation of [MapNativeService] calling Rust FFI methods in passenger_app.
 */
class MapNativeServiceImpl implements MapNativeService {
  @override
  Future<List<PlaceModel>> searchPlaces({
    required String token,
    required String query,
    double? proximityLat,
    double? proximityLng,
    double? userLat,
    double? userLng,
  }) async {
    final rustResults = await rust_api.searchPlaces(
      token: token,
      query: query,
      proximityLat: proximityLat,
      proximityLng: proximityLng,
      userLat: userLat,
      userLng: userLng,
    );

    return rustResults
        .map(
          (r) => PlaceModel(
            id: r.id,
            name: r.name,
            fullAddress: r.fullAddress,
            latitude: r.latitude,
            longitude: r.longitude,
            category: r.category,
            distanceKm: r.distanceKm,
          ),
        )
        .toList();
  }

  @override
  Future<PlaceModel?> reverseGeocode({
    required String token,
    required double lat,
    required double lng,
  }) async {
    final rustResult = await rust_api.reverseGeocode(
      token: token,
      lat: lat,
      lng: lng,
    );

    if (rustResult == null) return null;

    return PlaceModel(
      id: rustResult.id,
      name: rustResult.name,
      fullAddress: rustResult.fullAddress,
      latitude: rustResult.latitude,
      longitude: rustResult.longitude,
      category: rustResult.category,
    );
  }

  @override
  Future<RouteModel?> getRoute({
    required String token,
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    final rustResult = await rust_api.getRoute(
      token: token,
      originLat: originLat,
      originLng: originLng,
      destLat: destLat,
      destLng: destLng,
    );

    if (rustResult == null) return null;

    final points = rustResult.polylinePoints
        .map<List<double>>((p) => [p.lng, p.lat])
        .toList();

    return RouteModel(
      polylinePoints: points,
      distanceKm: rustResult.distanceKm,
      durationSeconds: rustResult.durationSeconds.round(),
      summary: rustResult.summary,
    );
  }

  @override
  Future<List<PlaceModel>> getNearbyPois({
    required String token,
    required double lat,
    required double lng,
  }) async {
    final rustResults = await rust_api.getNearbyPois(
      token: token,
      lat: lat,
      lng: lng,
    );

    return rustResults
        .map(
          (r) => PlaceModel(
            id: r.id,
            name: r.name,
            fullAddress: r.fullAddress,
            latitude: r.latitude,
            longitude: r.longitude,
            category: r.category,
            distanceKm: r.distanceKm,
          ),
        )
        .toList();
  }

  @override
  Future<double> haversineDistance({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) async {
    return await rust_api.haversineDistance(
      lat1: lat1,
      lng1: lng1,
      lat2: lat2,
      lng2: lng2,
    );
  }
}
