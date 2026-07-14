import 'package:core_models/core_models.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:location_service/location_service.dart';
import 'package:passenger_app/src/core/services/passenger_api_service.dart';

/// Fetches road-snapped route coordinates via Mapbox and manages active ride tracking.
class TrackRepositoryImpl implements TrackRepository {
  final PassengerApiService _apiService;

  TrackRepositoryImpl({required PassengerApiService apiService})
    : _apiService = apiService;

  @override
  Future<List<List<double>>?> getRoutePolyline({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      final route = await MapProvider.getRoute(
        startLat,
        startLng,
        endLat,
        endLng,
      );
      if (route != null && route.polylinePoints.isNotEmpty) {
        return route.polylinePoints;
      }
      return _linearInterpolation(startLat, startLng, endLat, endLng);
    } catch (error) {
      debugPrint('TrackRepositoryImpl.getRoutePolyline failed: $error');
      return _linearInterpolation(startLat, startLng, endLat, endLng);
    }
  }

  @override
  Future<Either<Failure, RideUpdate>> getRideStatusUpdate(String rideId) async {
    try {
      final data = await _apiService.getRideStatus(rideId);
      if (data != null) {
        return Right(RideUpdate.fromJson(data));
      }
      return const Left(
        ServerFailure('No status data returned from server.'),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, (double latitude, double longitude)>>
  fetchDriverLocation(String driverId) async {
    try {
      final locData = await _apiService.fetchDriverLocation(driverId);
      if (locData != null && locData['lat'] != null && locData['lng'] != null) {
        final lat = (locData['lat'] as num).toDouble();
        final lng = (locData['lng'] as num).toDouble();
        return Right((lat, lng));
      }
      return const Left(
        ServerFailure('Driver location coordinates unavailable.'),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateRideStatus(
    String rideId,
    RideStatus status,
  ) async {
    try {
      final success = await _apiService.updateRideStatus(rideId, status.value);
      if (success) {
        return const Right(null);
      }
      return const Left(
        ServerFailure('Failed to update ride status on server.'),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }

  List<List<double>> _linearInterpolation(
    double startLat,
    double startLng,
    double endLat,
    double endLng, {
    int steps = 5,
  }) {
    final points = <List<double>>[];
    for (var index = 0; index <= steps; index++) {
      final t = index / steps;
      points.add([
        startLat + (endLat - startLat) * t,
        startLng + (endLng - startLng) * t,
      ]);
    }
    return points;
  }
}
