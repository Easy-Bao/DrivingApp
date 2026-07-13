import 'package:core_models/core_models.dart';
import 'package:driver_app/src/core/services/driver_api_service.dart';
import 'package:driver_app/src/features/driver_dispatch/domain/repositories/driver_activity_repository.dart';

class DriverActivityRepositoryImpl implements DriverActivityRepository {
  final DriverApiService _apiService;

  DriverActivityRepositoryImpl({required DriverApiService apiService})
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
  Future<List<dynamic>> fetchTripHistory(String driverId) async {
    try {
      return await _apiService.fetchTripHistory(driverId);
    } catch (error) {
      throw _mapExceptionToFailure(error);
    }
  }
}
