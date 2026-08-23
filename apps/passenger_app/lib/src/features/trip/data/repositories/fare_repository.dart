import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/features/trip/data/datasources/fare_remote_data_source.dart';
import 'package:passenger_app/src/features/trip/domain/repositories/i_fare_repository.dart';
import 'package:shared_core/shared_core.dart';

class FareRepository implements IFareRepository {
  FareRepository({required FareRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final FareRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, FareResult>> estimateFare({
    required double distanceKm,
    required double durationMinutes,
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
  }) async {
    if (!_validCoordinate(originLatitude, originLongitude) ||
        !_validCoordinate(destinationLatitude, destinationLongitude) ||
        !distanceKm.isFinite ||
        distanceKm <= 0 ||
        !durationMinutes.isFinite ||
        durationMinutes <= 0) {
      return const Left(ValidationFailure('The trip route is invalid.'));
    }
    try {
      final fare = await _remoteDataSource.fetchEstimate(
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
        originLatitude: originLatitude,
        originLongitude: originLongitude,
        destinationLatitude: destinationLatitude,
        destinationLongitude: destinationLongitude,
      );
      if (!fare.totalFare.isFinite || fare.totalFare <= 0) {
        return const Left(ValidationFailure('The fare response is invalid.'));
      }
      return Right(fare);
    } on DioException catch (error) {
      if (error.response?.statusCode == null) {
        return const Left(
          NetworkFailure('Unable to calculate fare. Check your connection.'),
        );
      }
      return const Left(ServerFailure('Fare calculation is unavailable.'));
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (_) {
      return const Left(ServerFailure('Fare calculation is unavailable.'));
    }
  }
}

bool _validCoordinate(double latitude, double longitude) {
  return latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
}
