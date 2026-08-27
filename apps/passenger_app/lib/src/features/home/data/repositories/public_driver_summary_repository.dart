import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/features/home/data/datasources/public_driver_remote_data_source.dart';
import 'package:passenger_app/src/features/home/domain/entities/public_driver_summary.dart';
import 'package:passenger_app/src/features/home/domain/repositories/i_public_driver_summary_repository.dart';
import 'package:shared_core/shared_core.dart';

class PublicDriverSummaryRepository implements IPublicDriverSummaryRepository {
  final PublicDriverRemoteDataSource _remoteDataSource;

  PublicDriverSummaryRepository({
    required PublicDriverRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, List<PublicDriverSummary>>> fetchSummaries() async {
    try {
      final rawItems = await _remoteDataSource.fetchSummaries();
      final summaries = rawItems
          .map(_mapSummary)
          .where((summary) => summary.id.isNotEmpty)
          .toList(growable: false);
      return Right(summaries);
    } catch (error) {
      return Left(_mapExceptionToFailure(error));
    }
  }

  PublicDriverSummary _mapSummary(Map<String, dynamic> data) {
    return PublicDriverSummary(
      id: data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? 'Verified driver',
      vehicleType:
          data['vehicle_type']?.toString() ??
          data['vehicleType']?.toString() ??
          'Vehicle',
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
    );
  }

  Failure _mapExceptionToFailure(Object error) {
    if (error is ServerException) {
      if (error.statusCode == 400 || error.statusCode == 422) {
        return const ValidationFailure('Invalid driver summary response.');
      }
      return ServerFailure.withStatusCode(
        'Driver summaries are temporarily unavailable. Please try again.',
        error.statusCode,
      );
    }
    if (error is DataParsingException) {
      return FailureMapper.fromException(
        error,
        serverMessage:
            'Driver summaries are temporarily unavailable. Please try again.',
      );
    }
    return const ServerFailure(
      'Driver summaries are temporarily unavailable. Please try again.',
    );
  }
}
