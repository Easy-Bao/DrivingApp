import 'package:core_models/core_models.dart';
import 'package:driver_services/driver_services.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final TripApiService _apiService;

  DashboardRepositoryImpl({required TripApiService apiService})
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

  Future<String> _getDriverId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('driver_id') ?? '';
    } catch (error) {
      throw CacheException(
        message: 'Failed to access local preferences: $error',
      );
    }
  }

  @override
  Future<Either<Failure, double>> getTodayEarnings() async {
    try {
      final driverId = await _getDriverId();
      if (driverId.isEmpty) {
        return const Left(CacheFailure('Driver ID is not registered.'));
      }
      final data = await _apiService.fetchStats(driverId);
      return Right((data?['todayEarnings'] as num?)?.toDouble() ?? 0.0);
    } catch (error) {
      return Left(_mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, int>> getTodayTrips() async {
    try {
      final driverId = await _getDriverId();
      if (driverId.isEmpty) {
        return const Left(CacheFailure('Driver ID is not registered.'));
      }
      final data = await _apiService.fetchStats(driverId);
      return Right((data?['todayTrips'] as int?) ?? 0);
    } catch (error) {
      return Left(_mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, double>> getHoursOnline() async {
    try {
      final driverId = await _getDriverId();
      if (driverId.isEmpty) {
        return const Left(CacheFailure('Driver ID is not registered.'));
      }
      final data = await _apiService.fetchStats(driverId);
      return Right((data?['hoursOnline'] as num?)?.toDouble() ?? 0.0);
    } catch (error) {
      return Left(_mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, List<HeatmapCell>>> getSurgeHeatmap({
    required double lat,
    required double lng,
    required int gridSize,
    required double cellSize,
    required List<double> requestLats,
    required List<double> requestLngs,
  }) async {
    try {
      const surgeOffsets = [
        {'latOffset': 0.002, 'lngOffset': -0.002, 'intensity': 2.5},
        {'latOffset': -0.001, 'lngOffset': 0.003, 'intensity': 1.8},
        {'latOffset': 0.005, 'lngOffset': 0.001, 'intensity': 3.1},
      ];
      final cells = surgeOffsets
          .map(
            (o) => HeatmapCell(
              lat: lat + (o['latOffset'] ?? 0.0),
              lng: lng + (o['lngOffset'] ?? 0.0),
              intensity: o['intensity'] ?? 0.0,
            ),
          )
          .toList();
      return Right(cells);
    } catch (error) {
      return Left(_mapExceptionToFailure(error));
    }
  }
}
