import 'package:passenger_app/src/features/booking/booking.dart';
import 'package:fpdart/fpdart.dart';
import 'package:foundation/foundation.dart';

abstract interface class DriverRepository {
  Future<Either<Failure, List<DriverModel>>> getNearbyDrivers({
    required double lat,
    required double lng,
  });
}
