import 'package:driver/src/features/earnings/data/data_sources/driver_earnings_remote_data_source.dart';
import 'package:driver/src/features/earnings/domain/entities/driver_earnings_summary.dart';
import 'package:driver/src/features/earnings/domain/repositories/driver_earnings_repository.dart';
import 'package:foundation/foundation.dart';

final class EarningsRepositoryImpl({required this._dataSource})
    implements EarningsRepository {
  final EarningsRemoteDataSource _dataSource;

  @override
  Future<Result<EarningsSummary, Failure>> fetchEarningsSummary(
    String driverId,
  ) async {
    try {
      final raw = await _dataSource.fetchEarningsSummary(driverId);
      final data = raw['data'] is Map
          ? Map<String, dynamic>.from(raw['data'] as Map)
          : raw;
      return Ok(EarningsSummary.fromJson(data));
    } catch (error) {
      return Err(_mapExceptionToFailure(error));
    }
  }

  Failure _mapExceptionToFailure(Object error) {
    return FailureMapper.fromException(
      error,
      serverMessage:
          'Driver earnings are temporarily unavailable. Please try again.',
      validationMessage: 'Invalid driver earnings request.',
      networkMessage: 'Unable to reach driver earnings services. Check your connection and try again.',
    );
  }
}
