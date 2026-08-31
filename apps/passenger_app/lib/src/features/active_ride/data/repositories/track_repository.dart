import 'package:ride/ride.dart';
import 'package:fpdart/fpdart.dart';
import 'package:maps/maps.dart';
import 'package:passenger_app/src/features/active_ride/data/data_sources/ride_remote_data_source.dart';
import 'package:passenger_app/src/features/active_ride/domain/repositories/i_track_repository.dart';
import 'package:shared_core/shared_core.dart';

class TrackRepository implements ITrackRepository {
  final RideRemoteDataSource _remoteDataSource;

  TrackRepository({required RideRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  @override
  Future<List<List<double>>?> getRoutePolyline({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      final route = await MapProvider.getRoute(
        startLat,
        startLng,
        endLat,
        endLng,
      );
      if (route != null && route.hasGeometry) {
        return route.validPolylinePoints;
      }
      return null;
    } catch (error) {
      return null;
    }
  }

  @override
  Future<Either<Failure, RideUpdate>> getRideStatusUpdate(String rideId) async {
    try {
      final data = await _remoteDataSource.fetchRide(rideId);
      if (data != null) {
        return Right(RideUpdateDto.fromJson(data).toDomain());
      }
      return const Left(ServerFailure('No status data returned from server.'));
    } on ServerException catch (e) {
      return Left(
        FailureMapper.fromException(
          e,
          serverMessage:
              'Ride status is temporarily unavailable. Please try again.',
        ),
      );
    } catch (_) {
      return const Left(
        ServerFailure(
          'Ride status is temporarily unavailable. Please try again.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, RideSnapshot>> fetchRide(String rideId) async {
    try {
      final data = await _remoteDataSource.fetchRide(rideId);
      if (data == null) {
        return const Left(ServerFailure('No ride data returned from server.'));
      }
      final ride = RideDto.fromJson(data, fallbackId: rideId).toDomain();
      if (ride.id.isEmpty || ride.status.isEmpty) {
        return const Left(
          ValidationFailure('The ride response is incomplete.'),
        );
      }
      return Right(ride);
    } on ServerException catch (error) {
      return Left(
        FailureMapper.fromException(
          error,
          serverMessage: 'Ride details are temporarily unavailable.',
        ),
      );
    } catch (_) {
      return const Left(
        ServerFailure('Ride details are temporarily unavailable.'),
      );
    }
  }

  @override
  Future<Either<Failure, RideCounterparty>> fetchCounterparty(
    String rideId,
  ) async {
    try {
      return Right(
        RideCounterparty.fromJson(
          await _remoteDataSource.fetchCounterparty(rideId),
        ),
      );
    } on ServerException catch (error) {
      return Left(
        FailureMapper.fromException(
          error,
          serverMessage: 'Driver contact details are temporarily unavailable.',
        ),
      );
    } catch (_) {
      return const Left(
        ServerFailure('Driver contact details are temporarily unavailable.'),
      );
    }
  }

  @override
  Future<Either<Failure, (double latitude, double longitude)>>
  fetchDriverLocation(String rideId) async {
    try {
      final locData = await _remoteDataSource.fetchDriverLocation(rideId);
      final latitude = SafeParse.toNullableDouble(
        locData?['latitude'] ?? locData?['lat'],
      );
      final longitude = SafeParse.toNullableDouble(
        locData?['longitude'] ?? locData?['lng'],
      );
      if (latitude != null && longitude != null) {
        return Right((latitude.toDouble(), longitude.toDouble()));
      }
      return const Left(
        ServerFailure('Driver location coordinates unavailable.'),
      );
    } on ServerException catch (e) {
      return Left(
        FailureMapper.fromException(
          e,
          serverMessage:
              'Driver location is temporarily unavailable. Please try again.',
        ),
      );
    } catch (_) {
      return const Left(
        ServerFailure(
          'Driver location is temporarily unavailable. Please try again.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> updateRideStatus(
    String rideId,
    RideStatus status,
  ) async {
    try {
      final success = await _remoteDataSource.updateStatus(
        rideId,
        status.value,
      );
      if (success) {
        return const Right(null);
      }
      return const Left(
        ServerFailure('Failed to update ride status on server.'),
      );
    } on ServerException catch (e) {
      return Left(
        FailureMapper.fromException(
          e,
          serverMessage:
              'The ride status could not be updated. Please try again.',
        ),
      );
    } catch (_) {
      return const Left(
        ServerFailure(
          'The ride status could not be updated. Please try again.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> publishPassengerLocation({
    required String rideId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final sent = await _remoteDataSource.sendPassengerLocation(
        rideId: rideId,
        latitude: latitude,
        longitude: longitude,
      );
      return sent
          ? const Right(null)
          : const Left(NetworkFailure('Passenger location was not accepted.'));
    } on ServerException catch (error) {
      return Left(
        FailureMapper.fromException(
          error,
          serverMessage: 'Unable to share your current trip location.',
        ),
      );
    } catch (_) {
      return const Left(
        NetworkFailure('Unable to share your current trip location.'),
      );
    }
  }
}
