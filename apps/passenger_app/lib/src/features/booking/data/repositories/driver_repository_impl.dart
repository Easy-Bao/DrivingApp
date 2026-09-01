import 'package:passenger_app/src/features/booking/booking.dart';
import 'package:passenger_app/src/features/auth/domain/failures/auth_failures.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:maps/maps.dart';
import 'package:passenger_app/src/features/booking/data/data_sources/driver_discovery_remote_data_source.dart';
import 'package:passenger_app/src/features/booking/domain/repositories/driver_repository.dart';
import 'package:foundation/foundation.dart';

final class DriverRepositoryImpl({
  required DriverDiscoveryRemoteDataSource discoveryDataSource,
  required LocationRepository locationRepository,
}) implements DriverRepository {
  final DriverDiscoveryRemoteDataSource _discoveryDataSource;
  final LocationRepository _locationRepository;

  Future<Either<Failure, List<DriverModel>>>? _activeNearbyLookup;
  ({double lat, double lng})? _activeNearbyCoordinates;

  this
    : _discoveryDataSource = discoveryDataSource,
      _locationRepository = locationRepository;

  Failure _mapExceptionToFailure(Object error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        return const AuthFailure(
          'Session expired or unauthorized. Please sign in again.',
        );
      }
      if (statusCode == null) {
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.sendTimeout ||
            error.type == DioExceptionType.receiveTimeout) {
          return const ServerFailure.withStatusCode(
            'Driver availability request timed out.',
            504,
          );
        }
        return const NetworkFailure(
          'Unable to check nearby drivers. Check your connection and try again.',
        );
      }
      return ServerFailure.withStatusCode(
        'Driver availability is temporarily unavailable. Please try again.',
        statusCode,
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
      return ServerFailure.withStatusCode(
        'Driver availability is temporarily unavailable. Please try again.',
        error.statusCode,
      );
    }
    if (error is DataParsingException) {
      return FailureMapper.fromException(
        error,
        validationMessage: 'Nearby driver data is invalid. Please try again.',
      );
    }
    if (error is CacheException) {
      return FailureMapper.fromException(error);
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
      final nearbyPoints = await _discoveryDataSource.fetchNearbyDrivers(
        latitude: lat,
        longitude: lng,
      );
      final validPoints = <Map<String, dynamic>>[];
      for (final rawPoint in nearbyPoints) {
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
        validPoints.add({
          'driver_id': driverId,
          'lat': pointLat,
          'lng': pointLng,
        });
      }
      if (validPoints.isEmpty) return const Right([]);
      if (validPoints.length > 10) {
        validPoints.removeRange(10, validPoints.length);
      }

      final driverIds = validPoints
          .map((point) => point['driver_id']! as String)
          .toSet()
          .toList(growable: false);
      final profileFuture = _discoveryDataSource.fetchOnlineDrivers(driverIds);
      final matrixFuture = _fetchTravelMetrics(lat, lng, validPoints);
      final profiles = await profileFuture;
      final travelMetrics = await matrixFuture;
      final pointsByDriverId = <String, Map<String, dynamic>>{
        for (var index = 0; index < validPoints.length; index++)
          validPoints[index]['driver_id']! as String: {
            ...validPoints[index],
            if (travelMetrics != null && index < travelMetrics.length)
              'travel_metric': travelMetrics[index],
          },
      };
      final rawList = profiles
          .map((profile) {
            final profileId = _stringValue(profile['id'] ?? profile['user_id']);
            final point = pointsByDriverId[profileId];
            if (point == null) return null;
            return {...profile, ...point};
          })
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
      return Right(_processNearbyDrivers(rawList, lat, lng));
    } catch (error) {
      return Left(_mapExceptionToFailure(error));
    }
  }

  Future<List<_TravelMetric>?> _fetchTravelMetrics(
    double originLat,
    double originLng,
    List<Map<String, dynamic>> points,
  ) async {
    try {
      final response = await _locationRepository.getTravelMatrix(
        body: {
          'origin': {'lat': originLat, 'lng': originLng},
          'destinations': [
            for (final point in points)
              {'lat': point['lat'], 'lng': point['lng']},
          ],
        },
      );
      final distances = response['distances_km'];
      final durations = response['durations_min'];
      if (distances is! List ||
          durations is! List ||
          distances.length != points.length ||
          durations.length != points.length) {
        return null;
      }
      return [
        for (var index = 0; index < points.length; index++)
          _TravelMetric(
            distanceKm: SafeParse.toNullableDouble(distances[index]),
            durationMinutes: SafeParse.toNullableDouble(durations[index]),
          ),
      ];
    } catch (_) {
      return null;
    }
  }

  List<DriverModel> _processNearbyDrivers(
    List<Map<String, dynamic>> rawDrivers,
    double userLat,
    double userLng,
  ) {
    final drivers = <DriverModel>[];
    for (final d in rawDrivers) {
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

      final travelMetric = d['travel_metric'] as _TravelMetric?;
      final matrixDistance = travelMetric?.distanceKm;
      final distanceKm =
          matrixDistance != null &&
              matrixDistance.isFinite &&
              matrixDistance >= 0
          ? matrixDistance
          : fallbackDistance;
      final matrixDuration = travelMetric?.durationMinutes;
      final etaMinutes =
          matrixDuration != null &&
              matrixDuration.isFinite &&
              matrixDuration >= 0
          ? matrixDuration.clamp(1.0, 30.0)
          : _calculateEta(distanceKm);
      final rating = SafeParse.toNullableDouble(d['rating']) ?? 0;
      final score = _calculateMatchingScore(distanceKm, rating, etaMinutes);

      final driver = _mapToDriverModel(d, distanceKm, etaMinutes, score);
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
      name: _stringValue(
        data['name'] ?? data['driver_name'] ?? data['driverName'],
      ),
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

class const _TravelMetric({this.distanceKm, this.durationMinutes}) {
  final double? distanceKm;
  final double? durationMinutes;
}
