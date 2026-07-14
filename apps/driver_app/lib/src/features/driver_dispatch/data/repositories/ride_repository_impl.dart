import 'package:core_models/core_models.dart';
import 'package:fpdart/fpdart.dart';
import 'package:location_service/location_service.dart';
import 'package:driver_app/src/core/services/bidding_api_service.dart';

class RideRepositoryImpl implements RideRepository {
  final BiddingApiService _apiService;

  RideRepositoryImpl({required BiddingApiService apiService})
    : _apiService = apiService;

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
      return ServerFailure('Server returned status code ${error.statusCode}.');
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
      final fare = await _apiService.fetchFareEstimate(
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
      );
      if (fare != null) {
        return Right(
          FareResult(
            baseFare: (fare['base_fare'] as num).toDouble(),
            distanceCharge: (fare['distance_charge'] as num).toDouble(),
            timeCharge: (fare['time_charge'] as num).toDouble(),
            surgeCharge: (fare['surge_charge'] as num).toDouble(),
            totalFare: (fare['total_fare'] as num).toDouble(),
          ),
        );
      }
      return const Left(ServerFailure('Failed to fetch fare estimate.'));
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
