import 'package:core_models/core_models.dart';
import 'package:fpdart/fpdart.dart';
import 'package:location_service/src/features/map/domain/failures/place_failure.dart';

abstract class MapNativeService {
  Future<Either<PlaceFailure, List<PlaceModel>>> searchPlaces({
    required String query,
    double? proximityLat,
    double? proximityLng,
    double? userLat,
    double? userLng,
  });

  Future<Either<PlaceFailure, PlaceModel>> reverseGeocode({
    required double lat,
    required double lng,
  });

  Future<Either<PlaceFailure, RouteModel>> getRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  });

  Future<Either<PlaceFailure, List<PlaceModel>>> getNearbyPois({
    required double lat,
    required double lng,
    int page = 1,
  });

  Future<double> haversineDistance({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  });
}
