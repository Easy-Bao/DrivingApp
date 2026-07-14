import 'package:fpdart/fpdart.dart';
import '../errors/failures.dart';
import '../models/ride_status.dart';
import '../models/ride_update.dart';

/// Contract defining tracking coordinates and active ride telemetry.
abstract class TrackRepository {
  Future<List<List<double>>?> getRoutePolyline({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  });

  Future<Either<Failure, RideUpdate>> getRideStatusUpdate(String rideId);

  Future<Either<Failure, (double latitude, double longitude)>>
  fetchDriverLocation(String driverId);

  Future<Either<Failure, void>> updateRideStatus(
    String rideId,
    RideStatus status,
  );
}
