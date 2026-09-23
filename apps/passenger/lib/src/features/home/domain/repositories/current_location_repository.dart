import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/home/domain/entities/current_location.dart';

abstract interface class CurrentLocationRepository {
  Future<Result<CurrentLocation, Failure>> getCurrentLocation();

  Stream<Result<CurrentLocation, Failure>> watchCurrentLocation();
}
