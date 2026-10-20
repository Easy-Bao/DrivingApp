import 'package:driver/src/features/ride_history/data/data_sources/driver_ride_history_remote_data_source.dart';
import 'package:driver/src/features/ride_history/domain/repositories/driver_ride_history_repository.dart';
import 'package:foundation/foundation.dart';

final class RideHistoryRepositoryImpl({required this._dataSource})
    implements RideHistoryRepository {
  final RideHistoryRemoteDataSource _dataSource;

  @override
  Future<Result<OffsetPage<Map<String, dynamic>>, Failure>> fetchTripHistory(
    String driverId, {
    int limit = 25,
    int offset = 0,
    bool activeOnly = false,
  }) async {
    try {
      return Ok(
        await _dataSource.fetchTripHistory(
          driverId,
          limit: limit,
          offset: offset,
          activeOnly: activeOnly,
        ),
      );
    } catch (error) {
      return Err(_mapExceptionToFailure(error));
    }
  }

  Failure _mapExceptionToFailure(Object error) {
    if (error is DataParsingException) {
      return const ValidationFailure(
        'Driver trip history data is invalid. Please try again.',
      );
    }
    return FailureMapper.fromException(
      error,
      serverMessage:
          'Driver trip history is temporarily unavailable. Please try again.',
      validationMessage: 'Invalid driver trip history request.',
      networkMessage: 'Unable to reach driver trip history services. Check your connection and try again.',
    );
  }
}
