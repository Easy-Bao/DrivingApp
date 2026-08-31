import 'package:fpdart/fpdart.dart';
import 'package:shared_core/shared_core.dart';

abstract class IDriverRepository {
  Future<Either<Failure, List<DriverModel>>> getNearbyDrivers({
    required double lat,
    required double lng,
  });
}
