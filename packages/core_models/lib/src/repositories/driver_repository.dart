import 'package:fpdart/fpdart.dart';

import '../errors/failures.dart';
import '../models/driver_model.dart';

abstract class DriverRepository {

  Future<Either<Failure, List<DriverModel>>> getNearbyDrivers({
    required double lat,
    required double lng,
  });
}
