import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/features/home/domain/entities/home_data.dart';
import 'package:foundation/foundation.dart';

abstract interface class HomeRepository {
  Future<Either<Failure, HomeData>> loadHomeData({
    required double lat,
    required double lng,
  });
}
