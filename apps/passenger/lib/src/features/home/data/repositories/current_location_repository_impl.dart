import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/home/data/data_sources/current_location_data_source.dart';
import 'package:passenger/src/features/home/domain/entities/current_location.dart';
import 'package:passenger/src/features/home/domain/failures/current_location_failure.dart';
import 'package:passenger/src/features/home/domain/repositories/current_location_repository.dart';

final class const CurrentLocationRepositoryImpl({required this._dataSource})
    implements CurrentLocationRepository {
  final CurrentLocationDataSource _dataSource;

  @override
  Future<Result<CurrentLocation, Failure>> getCurrentLocation() async {
    try {
      final position = await _dataSource.getCurrentPosition();
      if (position == null) {
        return const Err(CurrentLocationFailure());
      }
      return Ok(
        CurrentLocation(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );
    } catch (_) {
      return const Err(CurrentLocationFailure());
    }
  }

  @override
  Stream<Result<CurrentLocation, Failure>> watchCurrentLocation() async* {
    try {
      await for (final position in _dataSource.watchCurrentPosition()) {
        yield Ok(
          CurrentLocation(
            latitude: position.latitude,
            longitude: position.longitude,
          ),
        );
      }
    } catch (_) {
      yield const Err(CurrentLocationFailure());
    }
  }
}
