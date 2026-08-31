import 'package:passenger_app/src/features/booking/booking.dart';
import 'package:fpdart/fpdart.dart';
import 'package:foundation/foundation.dart';

abstract class IDriverRepository {
  Future<Either<Failure, List<DriverModel>>> getNearbyDrivers({
    required double lat,
    required double lng,
  });
}
