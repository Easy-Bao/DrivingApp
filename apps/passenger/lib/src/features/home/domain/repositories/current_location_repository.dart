import 'package:foundation/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger/src/features/home/domain/entities/current_location.dart';

abstract interface class CurrentLocationRepository {
  Future<Either<Failure, CurrentLocation>> getCurrentLocation();

  Stream<Either<Failure, CurrentLocation>> watchCurrentLocation();
}
