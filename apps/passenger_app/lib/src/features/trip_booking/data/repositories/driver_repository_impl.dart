import 'package:core_models/core_models.dart';
import 'package:fpdart/fpdart.dart';
import 'package:location_service/location_service.dart';
import 'package:passenger_app/src/core/services/passenger_api_service.dart';

class DriverRepositoryImpl implements DriverRepository {
  final PassengerApiService _apiService;

  DriverRepositoryImpl({required PassengerApiService apiService})
    : _apiService = apiService;

  Failure _mapExceptionToFailure(Object error) {
    if (error is ServerException) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        return const AuthFailure(
          'Session expired or unauthorized. Please sign in again.',
        );
      }
      if (error.statusCode == 400 || error.statusCode == 422) {
        return const ValidationFailure('Invalid request data.');
      }
      return ServerFailure('Server returned status code ${error.statusCode}.');
    }
    if (error is DataParsingException) {
      return ValidationFailure(error.message);
    }
    if (error is CacheException) {
      return CacheFailure(error.message);
    }
    return ServerFailure('Unexpected system error: $error');
  }

  @override
  Future<Either<Failure, List<DriverModel>>> getNearbyDrivers({
    required double lat,
    required double lng,
  }) async {
    try {
      final rawList = await _apiService.fetchOnlineDrivers();
      return Right(_processNearbyDrivers(rawList, lat, lng));
    } catch (error) {
      return Left(_mapExceptionToFailure(error));
    }
  }

  List<DriverModel> _processNearbyDrivers(
    List<dynamic> rawDrivers,
    double userLat,
    double userLng,
  ) {
    final List<DriverModel> drivers = [];
    for (final d in rawDrivers) {
      if (d is! Map<String, dynamic>) continue;
      final driverLat = (d['lat'] as num?)?.toDouble() ?? 0.0;
      final driverLng = (d['lng'] as num?)?.toDouble() ?? 0.0;

      final distanceKm = _calculateDistance(
        userLat,
        userLng,
        driverLat,
        driverLng,
      );
      if (distanceKm > 5.0) continue;

      final etaMinutes = _calculateEta(distanceKm);
      final rating = (d['rating'] as num?)?.toDouble() ?? 5.0;
      final score = _calculateMatchingScore(distanceKm, rating, etaMinutes);

      drivers.add(_mapToDriverModel(d, distanceKm, etaMinutes, score));
    }

    drivers.sort((a, b) => a.score.compareTo(b.score));
    return drivers.take(5).toList();
  }

  double _calculateDistance(
    double userLat,
    double userLng,
    double driverLat,
    double driverLng,
  ) {
    return MapNativeServiceImpl.calculateHaversine(
      userLat,
      userLng,
      driverLat,
      driverLng,
    );
  }

  double _calculateEta(double distanceKm) {
    return (distanceKm / 20.0 * 60.0).clamp(1.0, 30.0);
  }

  double _calculateMatchingScore(
    double distanceKm,
    double rating,
    double etaMinutes,
  ) {
    return (0.5 * distanceKm) + (0.3 * (5.0 - rating)) + (0.2 * etaMinutes);
  }

  DriverModel _mapToDriverModel(
    Map<String, dynamic> data,
    double distanceKm,
    double etaMinutes,
    double score,
  ) {
    return DriverModel(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? 'Driver',
      vehicleType: data['vehicleType'] as String? ?? 'Bao Bao',
      plateNumber: data['plateNumber'] as String? ?? 'Unknown',
      rating: (data['rating'] as num?)?.toDouble() ?? 5.0,
      lat: (data['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (data['lng'] as num?)?.toDouble() ?? 0.0,
      distanceKm: distanceKm,
      etaMinutes: etaMinutes,
      score: score,
    );
  }
}
