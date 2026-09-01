import 'package:foundation/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger/src/features/home/domain/entities/home_data.dart';

abstract interface class HomeRepository {
  Future<Either<Failure, HomeData>> loadHomeData({
    required double lat,
    required double lng,
  });
}
