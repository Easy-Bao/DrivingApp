import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/core/location/repositories/map_native_service.dart';
import 'package:passenger_app/src/features/trip/data/datasources/bidding_remote_data_source.dart';
import 'package:passenger_app/src/features/trip/domain/repositories/i_driver_repository.dart';
import 'package:shared_core/shared_core.dart';

class DriverRepository implements IDriverRepository {
  final BiddingRemoteDataSource _biddingDataSource;

  Future<Either<Failure, List<DriverModel>>>? _activeNearbyLookup;
  ({double lat, double lng})? _activeNearbyCoordinates;

  DriverRepository({required BiddingRemoteDataSource biddingDataSource})
    : _biddingDataSource = biddingDataSource;

  Failure _mapExceptionToFailure(Object error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        return const AuthFailure(
          'Session expired or unauthorized. Please sign in again.',
        );
      }
      if (statusCode == null) {
        return const NetworkFailure(
          'Unable to check nearby drivers. Check your connection and try again.',
        );
      }
      return const ServerFailure(
        'Driver availability is temporarily unavailable. Please try again.',
      );
    }
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
    return const ServerFailure(
      'Driver availability is temporarily unavailable. Please try again.',
    );
  }

  @override
  Future<Either<Failure, List<DriverModel>>> getNearbyDrivers({
    required double lat,
    required double lng,
  }) async {
    if (!_isValidCoordinate(lat, lng)) {
      return const Left(ValidationFailure('Pickup location is invalid.'));
    }

    final activeLookup = _activeNearbyLookup;
    final activeCoordinates = _activeNearbyCoordinates;
    if (activeLookup != null &&
        activeCoordinates?.lat == lat &&
        activeCoordinates?.lng == lng) {
      return activeLookup;
    }

    final lookup = _loadNearbyDrivers(lat: lat, lng: lng);
    _activeNearbyLookup = lookup;
    _activeNearbyCoordinates = (lat: lat, lng: lng);
    try {
      return await lookup;
    } catch (error) {
      return Left(_mapExceptionToFailure(error));
    } finally {
      if (identical(_activeNearbyLookup, lookup)) {
        _activeNearbyLookup = null;
        _activeNearbyCoordinates = null;
      }
    }
  }

  Future<Either<Failure, List<DriverModel>>> _loadNearbyDrivers({
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
        final driverId = _stringValue(
          rawPoint['driver_id'] ?? rawPoint['driverId'],
        );
        final pointLat = SafeParse.toNullableDouble(
          rawPoint['latitude'] ?? rawPoint['lat'],
        );
        final pointLng = SafeParse.toNullableDouble(
          rawPoint['longitude'] ?? rawPoint['lng'],
        );
        if (driverId.isEmpty ||
            pointLat == null ||
            pointLng == null ||
            !_isValidCoordinate(pointLat, pointLng)) {
          continue;
        }
        pointsByDriverId[driverId] = {'lat': pointLat, 'lng': pointLng};
      }
      final rawList = profiles
          .whereType<Map<String, dynamic>>()
          .map((profile) {
            final profileId = _stringValue(profile['id'] ?? profile['user_id']);
            final point = pointsByDriverId[profileId];
            if (point == null) return null;
            return {...profile, ...point};
          })
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
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
      final driverLat = SafeParse.toNullableDouble(d['lat']);
      final driverLng = SafeParse.toNullableDouble(d['lng']);
      if (driverLat == null ||
          driverLng == null ||
          !_isValidCoordinate(driverLat, driverLng)) {
        continue;
      }

      final fallbackDistance = _calculateDistance(
        userLat,
        userLng,
        driverLat,
        driverLng,
      );
      if (fallbackDistance > 5.0) continue;

      final etaMinutes = _calculateEta(fallbackDistance);
      final rating = SafeParse.toNullableDouble(d['rating']) ?? 0;
      final score = _calculateMatchingScore(
        fallbackDistance,
        rating,
        etaMinutes,
      );

      final driver = _mapToDriverModel(d, fallbackDistance, etaMinutes, score);
      if (driver != null) drivers.add(driver);
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

  DriverModel? _mapToDriverModel(
    Map<String, dynamic> data,
    double distanceKm,
    double etaMinutes,
    double score,
  ) {
    final driverId = _stringValue(data['id'] ?? data['user_id']);
    if (driverId.isEmpty) return null;

    return DriverModel(
      id: driverId,
      name: _stringValue(data['name']),
      vehicleType: _stringValue(data['vehicleType'] ?? data['vehicle_type']),
      plateNumber: _stringValue(data['plateNumber'] ?? data['plate_number']),
      rating: SafeParse.toNullableDouble(data['rating']) ?? 0,
      lat: SafeParse.toNullableDouble(data['lat']) ?? 0,
      lng: SafeParse.toNullableDouble(data['lng']) ?? 0,
      distanceKm: distanceKm,
      etaMinutes: etaMinutes,
      score: score,
      onboardPassengerCount: _nullableInt(
        data['onboardPassengerCount'] ?? data['onboard_passenger_count'],
      ),
      avatarUrl: _nullableString(data['avatarUrl'] ?? data['avatar_url']),
      recentFeedback: _nullableString(
        data['recentFeedback'] ?? data['recent_feedback'],
      ),
    );
  }

  static String _stringValue(Object? value) {
    return value?.toString().trim() ?? '';
  }

  static String? _nullableString(Object? value) {
    final normalized = _stringValue(value);
    return normalized.isEmpty ? null : normalized;
  }

  static int? _nullableInt(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static bool _isValidCoordinate(double lat, double lng) {
    return lat.isFinite &&
        lng.isFinite &&
        lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180;
  }
}
