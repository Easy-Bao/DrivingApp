import 'package:fpdart/fpdart.dart';

import '../errors/failures.dart';
import '../models/driver_model.dart';

/// Contract: defines what the passenger feature needs for finding nearby drivers.
abstract class DriverRepository {
  /// Returns [Right] with nearby available drivers for the given coordinates,
  /// or [Left] with a [Failure] on network or parsing errors.
  Future<Either<Failure, List<DriverModel>>> getNearbyDrivers({
    required double lat,
    required double lng,
  });
}
