import 'package:core_models/core_models.dart';
import 'package:fpdart/fpdart.dart';

/// Abstract contract defining operations for retrieving driver trip histories.
abstract class DriverActivityRepository {
  /// Fetches all past and active trip history records associated with [driverId].
  ///
  /// Returns [Right] with raw trip maps or [Left] with a [Failure] on network
  /// or cache errors.
  Future<Either<Failure, List<dynamic>>> fetchTripHistory(String driverId);
}
