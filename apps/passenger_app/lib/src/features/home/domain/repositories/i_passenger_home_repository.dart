import 'package:fpdart/fpdart.dart';
import 'package:shared_core/shared_core.dart';

abstract class IPassengerHomeRepository {
  Future<Either<Failure, String>> resolveAddress({
    required double lat,
    required double lng,
  });

  Future<Either<Failure, List<Map<String, dynamic>>>> getRecentLocations();
}
