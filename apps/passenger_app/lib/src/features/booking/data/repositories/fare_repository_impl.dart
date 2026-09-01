import 'package:passenger_app/src/features/booking/booking.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/features/booking/data/data_sources/fare_remote_data_source.dart';
import 'package:passenger_app/src/features/booking/domain/repositories/fare_repository.dart';
import 'package:foundation/foundation.dart';

final class FareRepositoryImpl({required FareRemoteDataSource remoteDataSource})
    implements FareRepository {
  this : _remoteDataSource = remoteDataSource;

  final FareRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, FareEstimate>> estimateFare({
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
      final statusCode = error.response?.statusCode;
      if (statusCode == null) {
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.sendTimeout ||
            error.type == DioExceptionType.receiveTimeout) {
          return const Left(
            ServerFailure.withStatusCode('Fare request timed out.', 504),
          );
        }
        return const Left(
          NetworkFailure('Unable to calculate fare. Check your connection.'),
        );
      }
      if (statusCode == 400 || statusCode == 422) {
        return const Left(RouteCalculationFailure());
      }
      return Left(
        ServerFailure.withStatusCode(
          'Fare calculation is unavailable.',
          statusCode,
        ),
      );
    } on ServerException catch (error) {
      if (error.statusCode == 400 || error.statusCode == 422) {
        return const Left(RouteCalculationFailure());
      }
      return Left(
        FailureMapper.fromException(
          error,
          serverMessage: 'Fare calculation is unavailable.',
        ),
      );
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
