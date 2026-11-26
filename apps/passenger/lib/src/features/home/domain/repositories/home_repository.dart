import 'package:foundation/foundation.dart';
import 'package:maps/maps.dart';
import 'package:passenger/src/features/home/domain/entities/home_data.dart';

abstract interface class HomeRepository {
  Future<Result<HomeData, Failure>> loadHomeData({
    required double lat,
    required double lng,
  });

  Future<List<Place>> loadNearbyPlaces({
    required double lat,
    required double lng,
  });
}
