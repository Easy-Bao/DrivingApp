import 'package:core_models/core_models.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger_services/src/features/bidding/data/datasources/bidding_remote_datasource.dart';
import 'package:passenger_services/src/features/bidding/domain/repositories/bidding_repository.dart';

class BiddingRepositoryImpl implements BiddingRepository {
  final BiddingRemoteDataSource _remoteDataSource;

  BiddingRepositoryImpl({required BiddingRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, Map<String, dynamic>?>> openBidSession({
    required String passengerId,
    required String rideType,
    required double pickupLat,
    required double pickupLng,
    required String pickupName,
    required double dropoffLat,
    required double dropoffLng,
    required String dropoffName,
    required double distanceKm,
    required double durationMinutes,
    String? targetDriverId,
  }) async {
    try {
      final session = await _remoteDataSource.openBidSession(
        passengerId: passengerId,
        rideType: rideType,
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        pickupName: pickupName,
        dropoffLat: dropoffLat,
        dropoffLng: dropoffLng,
        dropoffName: dropoffName,
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
        targetDriverId: targetDriverId,
      );
      return Right(session);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>?>> getBidSession(String sessionId) async {
    try {
      final session = await _remoteDataSource.getBidSession(sessionId);
      return Right(session);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, List<dynamic>>> pollBidOffers(String sessionId) async {
    try {
      final offers = await _remoteDataSource.pollBidOffers(sessionId);
      return Right(offers);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>?>> acceptBidOffer({
    required String sessionId,
    required String offerId,
  }) async {
    try {
      final acceptResult = await _remoteDataSource.acceptBidOffer(
        sessionId: sessionId,
        offerId: offerId,
      );
      return Right(acceptResult);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> cancelBidSession(String sessionId) async {
    try {
      final result = await _remoteDataSource.cancelBidSession(sessionId);
      return Right(result);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>?>> fetchFareEstimate({
    required String rideType,
    required double distanceKm,
    required double durationMinutes,
  }) async {
    try {
      final estimate = await _remoteDataSource.fetchFareEstimate(
        rideType: rideType,
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
      );
      return Right(estimate);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }
}
