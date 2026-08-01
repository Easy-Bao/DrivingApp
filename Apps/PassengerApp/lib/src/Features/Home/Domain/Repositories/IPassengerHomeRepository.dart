import 'package:core_models/CoreModels.dart';
import 'package:fpdart/fpdart.dart';

abstract class IPassengerHomeRepository {
  Future<Either<Failure, String>> resolveAddress({
    required double lat,
    required double lng,
  });

  Future<Either<Failure, List<Map<String, dynamic>>>> getRecentLocations();
}
