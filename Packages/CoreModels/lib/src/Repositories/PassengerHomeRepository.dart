import 'package:fpdart/fpdart.dart';

import '../Errors/Failures.dart';

abstract class PassengerHomeRepository {

  Future<Either<Failure, String>> resolveAddress({
    required double lat,
    required double lng,
  });

  Future<Either<Failure, List<Map<String, dynamic>>>> getRecentLocations();
}
