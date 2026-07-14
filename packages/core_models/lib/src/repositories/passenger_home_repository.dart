import 'package:fpdart/fpdart.dart';

import '../errors/failures.dart';

/// Contract: what the PassengerHome feature needs from the data layer.
/// Covers location resolution and recent place history.
abstract class PassengerHomeRepository {
  /// Resolves the current address for the given coordinates.
  ///
  /// Returns [Right] with a display-ready address string or [Left] with a
  /// [Failure] if reverse geocoding fails.
  Future<Either<Failure, String>> resolveAddress({
    required double lat,
    required double lng,
  });

  /// Returns [Right] with the passenger's recent destinations or [Left]
  /// with a [Failure] if the ride history lookup fails.
  Future<Either<Failure, List<Map<String, dynamic>>>> getRecentLocations();
}
