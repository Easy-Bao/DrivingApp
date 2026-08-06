import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/core/location/repositories/map_native_service.dart';
import 'package:passenger_app/src/features/trip/data/datasources/bidding_remote_data_source.dart';
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
      final responses = await Future.wait<List<dynamic>>([
        _biddingDataSource.fetchOnlineDrivers(),
        _biddingDataSource.fetchNearbyDrivers(latitude: lat, longitude: lng),
      ]);
      final profiles = responses[0];
      final nearbyPoints = responses[1];
      final pointsByDriverId = <String, Map<String, dynamic>>{};
      for (final rawPoint in nearbyPoints.whereType<Map<String, dynamic>>()) {
        final driverId =
            rawPoint['driver_id']?.toString() ??
            rawPoint['driverId']?.toString();
        final pointLat = (rawPoint['latitude'] as num?)?.toDouble();
        final pointLng = (rawPoint['longitude'] as num?)?.toDouble();
        if (driverId == null ||
            driverId.isEmpty ||
            pointLat == null ||
            pointLng == null) {
          continue;
        }
        pointsByDriverId[driverId] = {'lat': pointLat, 'lng': pointLng};
      }
      final rawList = profiles
          .whereType<Map<String, dynamic>>()
          .map((profile) {
            final profileId =
                profile['id']?.toString() ?? profile['user_id']?.toString();
            final point = pointsByDriverId[profileId];
            if (point == null) return null;
            return {...profile, ...point};
          })
          .whereType<Map<String, dynamic>>()
          .toList();
      // The realtime service already applies the radius query. Haversine keeps
      // ranking local and avoids depending on the unregistered matrix route.
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
      final driverLat = (d['lat'] as num?)?.toDouble();
      final driverLng = (d['lng'] as num?)?.toDouble();
      if (driverLat == null || driverLng == null) continue;

      final fallbackDistance = _calculateDistance(
        userLat,
        userLng,
        driverLat,
        driverLng,
      );
      if (fallbackDistance > 5.0) continue;

      final etaMinutes = _calculateEta(fallbackDistance);
      final rating = (d['rating'] as num?)?.toDouble() ?? 0;
      final score = _calculateMatchingScore(
        fallbackDistance,
        rating,
        etaMinutes,
      );

      drivers.add(_mapToDriverModel(d, fallbackDistance, etaMinutes, score));
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
      id: data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      vehicleType:
          data['vehicleType']?.toString() ??
          data['vehicle_type']?.toString() ??
          '',
      plateNumber:
          data['plateNumber']?.toString() ??
          data['plate_number']?.toString() ??
          '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      lat: (data['lat'] as num?)?.toDouble() ?? 0,
      lng: (data['lng'] as num?)?.toDouble() ?? 0,
      distanceKm: distanceKm,
      etaMinutes: etaMinutes,
      score: score,
      onboardPassengerCount:
          (data['onboardPassengerCount'] as num?)?.toInt() ??
          (data['onboard_passenger_count'] as num?)?.toInt(),
      avatarUrl: data['avatarUrl'] as String? ?? data['avatar_url'] as String?,
      recentFeedback:
          data['recentFeedback'] as String? ??
          data['recent_feedback'] as String?,
    );
  }
}
