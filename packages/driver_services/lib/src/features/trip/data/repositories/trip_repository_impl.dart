import 'package:core_models/core_models.dart';
import 'package:driver_services/src/features/trip/data/datasources/trip_remote_datasource.dart';
import 'package:driver_services/src/features/trip/domain/repositories/trip_repository.dart';
import 'package:fpdart/fpdart.dart';

class TripRepositoryImpl implements TripRepository {
  final TripRemoteDataSource _remoteDataSource;

  TripRepositoryImpl({required TripRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, List<dynamic>>> fetchTripHistory(String driverId) async {
    try {
      final result = await _remoteDataSource.fetchTripHistory(driverId);
      return Right(result);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> fetchStats(String driverId) async {
    try {
      final result = await _remoteDataSource.fetchStats(driverId);
      return Right(result);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getRideStatus(String rideId) async {
    try {
      final result = await _remoteDataSource.getRideStatus(rideId);
      return Right(result);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> acceptRide({
    required String rideId,
    required String driverId,
    required String driverName,
    required String driverRating,
    required String vehicleType,
    required String plateNumber,
  }) async {
    try {
      final result = await _remoteDataSource.acceptRide(
        rideId: rideId,
        driverId: driverId,
        driverName: driverName,
        driverRating: driverRating,
        vehicleType: vehicleType,
        plateNumber: plateNumber,
      );
      return Right(result);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> updateRideStatus(String rideId, String status) async {
    try {
      final result = await _remoteDataSource.updateRideStatus(rideId, status);
      return Right(result);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }
}
