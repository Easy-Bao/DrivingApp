import 'package:core_models/core_models.dart';
import 'package:driver_services/src/features/telemetry/data/datasources/telemetry_remote_datasource.dart';
import 'package:driver_services/src/features/telemetry/domain/repositories/telemetry_repository.dart';
import 'package:fpdart/fpdart.dart';

class TelemetryRepositoryImpl implements TelemetryRepository {
  final TelemetryRemoteDataSource _remoteDataSource;

  TelemetryRepositoryImpl({required TelemetryRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, bool>> updateLocation({
    required String driverId,
    required double lat,
    required double lng,
  }) async {
    try {
      final result = await _remoteDataSource.updateLocation(
        driverId: driverId,
        lat: lat,
        lng: lng,
      );
      return Right(result);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> fetchPassengerLocation(String rideId) async {
    try {
      final result = await _remoteDataSource.fetchPassengerLocation(rideId);
      return Right(result);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}
