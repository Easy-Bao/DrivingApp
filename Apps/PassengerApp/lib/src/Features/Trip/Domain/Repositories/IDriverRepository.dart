import 'package:core_models/CoreModels.dart';
import 'package:fpdart/fpdart.dart';

abstract class IDriverRepository {
  Future<Either<Failure, List<DriverModel>>> getNearbyDrivers({
    required double lat,
    required double lng,
  });
}
