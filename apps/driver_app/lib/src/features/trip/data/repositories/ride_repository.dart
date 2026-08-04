import 'package:shared_core/shared_core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:driver_app/src/features/trip/domain/repositories/i_ride_repository.dart';
import 'package:driver_app/src/features/trip/data/data_sources/bidding_remote_data_source.dart';

class RideRepository implements IRideRepository {
  final BiddingRemoteDataSource _remoteDataSource;

  RideRepository({required BiddingRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  Failure _mapExceptionToFailure(Object error) {
    if (error is ServerException) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        return const AuthFailure(
          'Session expired or unauthorized. Please sign in again.',
        );
      }
      if (error.statusCode == 400 || error.statusCode == 422) {
        return const ValidationFailure('Invalid request data.');
      }
      return ServerFailure(error.message);
    }
    if (error is DataParsingException) {
      return ValidationFailure(error.message);
    }
    if (error is CacheException) {
      return CacheFailure(error.message);
    }
    return ServerFailure('Unexpected system error: $error');
  }

  @override
  Future<Either<Failure, FareResult>> getFare({
    required double distanceKm,
    required double durationMinutes,
  }) async {
    try {
      final fare = await _remoteDataSource.fetchFareEstimate(
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
      );
      return Right(
        FareResult(
          baseFare: (fare['base_fare'] as num).toDouble(),
          distanceCharge: (fare['distance_charge'] as num).toDouble(),
          timeCharge: (fare['time_charge'] as num).toDouble(),
          surgeCharge: (fare['surge_charge'] as num).toDouble(),
          totalFare: (fare['total_fare'] as num).toDouble(),
        ),
      );
    } catch (error) {
      return Left(_mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, RouteSequenceResult>> optimizeRoute({
    required double startLat,
    required double startLng,
    required List<Waypoint> waypoints,
  }) async {
    try {
      final result = RouteOptimizationService.calculateOptimalRoute(
        startLat: startLat,
        startLng: startLng,
        waypoints: waypoints,
      );
      return Right(result);
    } catch (error) {
      return Left(ServerFailure('Failed to optimize route sequence: $error'));
    }
  }
}
