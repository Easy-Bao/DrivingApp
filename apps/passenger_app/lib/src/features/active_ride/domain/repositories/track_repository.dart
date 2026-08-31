import 'package:passenger_app/src/features/active_ride/active_ride.dart';
import 'package:fpdart/fpdart.dart';
import 'package:foundation/foundation.dart';

abstract interface class TrackRepository {
  Future<List<List<double>>?> getRoutePolyline({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  });

  Future<Either<Failure, RideUpdate>> getRideStatusUpdate(String rideId);

  Future<Either<Failure, RideSnapshot>> fetchRide(String rideId);

  Future<Either<Failure, RideCounterparty>> fetchCounterparty(String rideId);

  Future<Either<Failure, (double latitude, double longitude)>>
  fetchDriverLocation(String rideId);

  Future<Either<Failure, void>> updateRideStatus(
    String rideId,
    RideStatus status,
  );

  Future<Either<Failure, void>> publishPassengerLocation({
    required String rideId,
    required double latitude,
    required double longitude,
  });
}
