import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/core/location/location.dart';
import 'package:passenger_app/src/features/trip/data/datasources/bidding_remote_data_source.dart';
import 'package:passenger_app/src/features/trip/domain/repositories/i_track_repository.dart';
import 'package:shared_core/shared_core.dart';

class TrackRepository implements ITrackRepository {
  final BiddingRemoteDataSource _biddingDataSource;

  TrackRepository({required BiddingRemoteDataSource biddingDataSource})
    : _biddingDataSource = biddingDataSource;

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
      final data = await _biddingDataSource.getRideStatus(rideId);
      if (data != null) {
        return Right(RideUpdate.fromJson(data));
      }
      return const Left(ServerFailure('No status data returned from server.'));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(
        ServerFailure(
          'Ride status is temporarily unavailable. Please try again.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, (double latitude, double longitude)>>
  fetchDriverLocation(String rideId) async {
    try {
      final locData = await _biddingDataSource.fetchDriverLocation(rideId);
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
      return Left(ServerFailure(e.message));
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
      final success = await _biddingDataSource.updateRideStatus(
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
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(
        ServerFailure(
          'The ride status could not be updated. Please try again.',
        ),
      );
    }
  }
}
