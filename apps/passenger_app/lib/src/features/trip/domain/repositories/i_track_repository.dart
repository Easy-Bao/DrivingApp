import 'package:fpdart/fpdart.dart';
import 'package:shared_core/shared_core.dart';

abstract class ITrackRepository {
  Future<List<List<double>>?> getRoutePolyline({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  });

  Future<Either<Failure, RideUpdate>> getRideStatusUpdate(String rideId);

  Future<Either<Failure, (double latitude, double longitude)>>
  fetchDriverLocation(String rideId);

  Future<Either<Failure, void>> updateRideStatus(
    String rideId,
    RideStatus status,
  );
}
