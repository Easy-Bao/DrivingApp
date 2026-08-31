import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/features/home/data/data_sources/current_location_data_source.dart';
import 'package:passenger_app/src/features/home/domain/entities/current_location.dart';
import 'package:passenger_app/src/features/home/domain/failures/current_location_failure.dart';
import 'package:passenger_app/src/features/home/domain/repositories/i_current_location_repository.dart';
import 'package:shared_core/shared_core.dart';

class CurrentLocationRepository implements ICurrentLocationRepository {
  const CurrentLocationRepository({
    required CurrentLocationDataSource dataSource,
  }) : _dataSource = dataSource;

  final CurrentLocationDataSource _dataSource;

  @override
  Future<Either<Failure, CurrentLocation>> getCurrentLocation() async {
    try {
      final position = await _dataSource.getCurrentPosition();
      if (position == null) {
        return const Left(CurrentLocationFailure());
      }
      return Right(
        CurrentLocation(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );
    } catch (_) {
      return const Left(CurrentLocationFailure());
    }
  }

  @override
  Stream<Either<Failure, CurrentLocation>> watchCurrentLocation() async* {
    try {
      await for (final position in _dataSource.watchCurrentPosition()) {
        yield Right(
          CurrentLocation(
            latitude: position.latitude,
            longitude: position.longitude,
          ),
        );
      }
    } catch (_) {
      yield const Left(CurrentLocationFailure());
    }
  }
}
