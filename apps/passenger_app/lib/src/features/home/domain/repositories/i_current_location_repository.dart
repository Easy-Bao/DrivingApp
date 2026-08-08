import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/features/home/domain/entities/current_location.dart';
import 'package:shared_core/shared_core.dart';

abstract interface class ICurrentLocationRepository {
  Future<Either<Failure, CurrentLocation>> getCurrentLocation();

  Stream<Either<Failure, CurrentLocation>> watchCurrentLocation();
}
