import 'package:fpdart/fpdart.dart';

import '../Errors/Failures.dart';
import '../Models/DriverModel.dart';

abstract class DriverRepository {

  Future<Either<Failure, List<DriverModel>>> getNearbyDrivers({
    required double lat,
    required double lng,
  });
}
