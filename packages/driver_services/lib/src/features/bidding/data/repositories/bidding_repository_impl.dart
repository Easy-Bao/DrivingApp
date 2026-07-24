import 'package:core_models/core_models.dart';
import 'package:driver_services/src/features/bidding/data/datasources/bidding_remote_datasource.dart';
import 'package:driver_services/src/features/bidding/domain/repositories/bidding_repository.dart';
import 'package:fpdart/fpdart.dart';

class BiddingRepositoryImpl implements BiddingRepository {
  final BiddingRemoteDataSource _remoteDataSource;

  BiddingRepositoryImpl({required BiddingRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, Map<String, dynamic>>> fetchFareEstimate({
    required double distanceKm,
    required double durationMinutes,
    String rideType = 'Solo Ride',
  }) async {
    try {
      final result = await _remoteDataSource.fetchFareEstimate(
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
        rideType: rideType,
      );
      return Right(result);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<dynamic>>> fetchActiveBids(String driverId) async {
    try {
      final result = await _remoteDataSource.fetchActiveBids(driverId);
      return Right(result);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> placeBid({
    required String sessionId,
    required String driverId,
    required String driverName,
    required String plateNumber,
    required String vehicleType,
    double? proposedFare,
  }) async {
    try {
      final result = await _remoteDataSource.placeBid(
        sessionId: sessionId,
        driverId: driverId,
        driverName: driverName,
        plateNumber: plateNumber,
        vehicleType: vehicleType,
        proposedFare: proposedFare,
      );
      return Right(result);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> cancelBid({
    required String sessionId,
    required String driverId,
  }) async {
    try {
      final result = await _remoteDataSource.cancelBid(
        sessionId: sessionId,
        driverId: driverId,
      );
      return Right(result);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}
