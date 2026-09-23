import 'package:foundation/foundation.dart';
import 'package:maps/maps.dart';
import 'package:passenger/src/features/active_ride/active_ride.dart';
import 'package:passenger/src/features/active_ride/data/data_sources/ride_remote_data_source.dart';
import 'package:passenger/src/features/active_ride/domain/repositories/track_repository.dart';

final class TrackRepositoryImpl({required this._remoteDataSource})
    implements TrackRepository {
  final RideRemoteDataSource _remoteDataSource;

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
  Future<Result<RideUpdate, Failure>> getRideStatusUpdate(String rideId) async {
    try {
      final data = await _remoteDataSource.fetchRide(rideId);
      if (data != null) {
        return Ok(RideUpdateDto.fromJson(data).toDomain());
      }
      return const Err(ServerFailure('No status data returned from server.'));
    } on ServerException catch (e) {
      return Err(
        FailureMapper.fromException(
          e,
          serverMessage:
              'Ride status is temporarily unavailable. Please try again.',
        ),
      );
    } catch (_) {
      return const Err(
        ServerFailure(
          'Ride status is temporarily unavailable. Please try again.',
        ),
      );
    }
  }

  @override
  Future<Result<RideSnapshot, Failure>> fetchRide(String rideId) async {
    try {
      final data = await _remoteDataSource.fetchRide(rideId);
      if (data == null) {
        return const Err(ServerFailure('No ride data returned from server.'));
      }
      final ride = RideDto.fromJson(data, fallbackId: rideId).toDomain();
      if (ride.id.isEmpty || ride.status.isEmpty) {
        return const Err(ValidationFailure('The ride response is incomplete.'));
      }
      return Ok(ride);
    } on ServerException catch (error) {
      return Err(
        FailureMapper.fromException(
          error,
          serverMessage: 'Ride details are temporarily unavailable.',
        ),
      );
    } catch (_) {
      return const Err(
        ServerFailure('Ride details are temporarily unavailable.'),
      );
    }
  }

  @override
  Future<Result<RideCounterparty, Failure>> fetchCounterparty(
    String rideId,
  ) async {
    try {
      return Ok(
        RideCounterparty.fromJson(
          await _remoteDataSource.fetchCounterparty(rideId),
        ),
      );
    } on ServerException catch (error) {
      return Err(
        FailureMapper.fromException(
          error,
          serverMessage: 'Driver contact details are temporarily unavailable.',
        ),
      );
    } catch (_) {
      return const Err(
        ServerFailure('Driver contact details are temporarily unavailable.'),
      );
    }
  }

  @override
  Future<Result<(double latitude, double longitude), Failure>>
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
        return Ok((latitude.toDouble(), longitude.toDouble()));
      }
      return const Err(
        ServerFailure('Driver location coordinates unavailable.'),
      );
    } on ServerException catch (e) {
      return Err(
        FailureMapper.fromException(
          e,
          serverMessage:
              'Driver location is temporarily unavailable. Please try again.',
        ),
      );
    } catch (_) {
      return const Err(
        ServerFailure(
          'Driver location is temporarily unavailable. Please try again.',
        ),
      );
    }
  }

  @override
  Future<Result<void, Failure>> updateRideStatus(
    String rideId,
    RideStatus status,
  ) async {
    try {
      final success = await _remoteDataSource.updateStatus(
        rideId,
        status.value,
      );
      if (success) {
        return const Ok(null);
      }
      return const Err(
        ServerFailure('Failed to update ride status on server.'),
      );
    } on ServerException catch (e) {
      return Err(
        FailureMapper.fromException(
          e,
          serverMessage:
              'The ride status could not be updated. Please try again.',
        ),
      );
    } catch (_) {
      return const Err(
        ServerFailure(
          'The ride status could not be updated. Please try again.',
        ),
      );
    }
  }

  @override
  Future<Result<void, Failure>> publishPassengerLocation({
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
          ? const Ok(null)
          : const Err(NetworkFailure('Passenger location was not accepted.'));
    } on ServerException catch (error) {
      return Err(
        FailureMapper.fromException(
          error,
          serverMessage: 'Unable to share your current trip location.',
        ),
      );
    } catch (_) {
      return const Err(
        NetworkFailure('Unable to share your current trip location.'),
      );
    }
  }
}
