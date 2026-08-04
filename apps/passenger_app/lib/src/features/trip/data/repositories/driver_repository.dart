import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/core/location/location.dart';
import 'package:passenger_app/src/features/booking/data/data_sources/bidding_remote_data_source.dart';
import 'package:passenger_app/src/features/trip/domain/repositories/i_driver_repository.dart';
import 'package:shared_core/shared_core.dart';

class DriverRepository implements IDriverRepository {
  final BiddingRemoteDataSource _biddingDataSource;

  DriverRepository({required BiddingRemoteDataSource biddingDataSource})
    : _biddingDataSource = biddingDataSource;

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
      final rawList = await _biddingDataSource.fetchOnlineDrivers();
      final candidates = rawList
          .whereType<Map<String, dynamic>>()
          .map((driver) {
            final driverLat = (driver['lat'] as num?)?.toDouble();
            final driverLng = (driver['lng'] as num?)?.toDouble();
            if (driverLat == null || driverLng == null) return null;
            return (lat: driverLat, lng: driverLng);
          })
          .whereType<({double lat, double lng})>()
          .take(24)
          .toList();
      final matrixDistances = await MapProvider.getDrivingDistances(
        originLat: lat,
        originLng: lng,
        destinations: candidates,
      );
      return Right(_processNearbyDrivers(rawList, lat, lng, matrixDistances));
    } catch (error) {
      return Left(_mapExceptionToFailure(error));
    }
  }

  List<DriverModel> _processNearbyDrivers(
    List<dynamic> rawDrivers,
    double userLat,
    double userLng,
    List<double>? matrixDistances,
  ) {
    final List<DriverModel> drivers = [];
    var matrixIndex = 0;
    for (final d in rawDrivers) {
      if (d is! Map<String, dynamic>) continue;
      final driverLat = (d['lat'] as num?)?.toDouble();
      final driverLng = (d['lng'] as num?)?.toDouble();
      if (driverLat == null || driverLng == null) continue;

      final fallbackDistance = _calculateDistance(
        userLat,
        userLng,
        driverLat,
        driverLng,
      );
      final distanceKm = matrixIndex < (matrixDistances?.length ?? 0)
          ? matrixDistances![matrixIndex]
          : fallbackDistance;
      matrixIndex++;
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
    return MapNativeService.calculateHaversine(
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
      hasPassengerOnboard:
          data['hasPassengerOnboard'] as bool? ??
          data['has_passenger_onboard'] as bool? ??
          ((data['id'] as String? ?? '').hashCode.abs() % 2 == 1),
      avatarUrl: data['avatarUrl'] as String? ?? data['avatar_url'] as String?,
      recentFeedback:
          data['recentFeedback'] as String? ??
          data['recent_feedback'] as String? ??
          'Smooth ride, polite driver and very clean vehicle.',
    );
  }
}
