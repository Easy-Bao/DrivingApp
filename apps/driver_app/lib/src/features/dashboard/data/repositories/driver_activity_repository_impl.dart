import 'package:core_models/core_models.dart';
import 'package:driver_app/src/features/dashboard/domain/repositories/driver_activity_repository.dart';
import 'package:driver_services/driver_services.dart';
import 'package:fpdart/fpdart.dart';

/// Repository implementation for reading driver trip history from the backend.
class DriverActivityRepositoryImpl implements DriverActivityRepository {
  final TripApiService _apiService;

  DriverActivityRepositoryImpl({required TripApiService apiService})
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
  Future<Either<Failure, List<dynamic>>> fetchTripHistory(
    String driverId,
  ) async {
    try {
      return Right(await _apiService.fetchTripHistory(driverId));
    } catch (error) {
      return Left(_mapExceptionToFailure(error));
    }
  }
}
