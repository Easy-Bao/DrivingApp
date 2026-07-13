import 'package:core_models/core_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:driver_app/src/core/services/driver_api_service.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DriverApiService _apiService;

  DashboardRepositoryImpl({required DriverApiService apiService})
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
    } catch (e) {
      throw CacheException(message: 'Failed to access local preferences: $e');
    }
  }

  @override
  Future<double> getTodayEarnings() async {
    try {
      final driverId = await _getDriverId();
      if (driverId.isEmpty) {
        throw const CacheFailure('Driver ID is not registered.');
      }
      final data = await _apiService.fetchStats(driverId);
      if (data != null && data['todayEarnings'] != null) {
        return (data['todayEarnings'] as num).toDouble();
      }
      return 0.0;
    } catch (error) {
      throw _mapExceptionToFailure(error);
    }
  }

  @override
  Future<int> getTodayTrips() async {
    try {
      final driverId = await _getDriverId();
      if (driverId.isEmpty) {
        throw const CacheFailure('Driver ID is not registered.');
      }
      final data = await _apiService.fetchStats(driverId);
      if (data != null && data['todayTrips'] != null) {
        return data['todayTrips'] as int;
      }
      return 0;
    } catch (error) {
      throw _mapExceptionToFailure(error);
    }
  }

  @override
  Future<double> getHoursOnline() async {
    try {
      final driverId = await _getDriverId();
      if (driverId.isEmpty) {
        throw const CacheFailure('Driver ID is not registered.');
      }
      final data = await _apiService.fetchStats(driverId);
      if (data != null && data['hoursOnline'] != null) {
        return (data['hoursOnline'] as num).toDouble();
      }
      return 0.0;
    } catch (error) {
      throw _mapExceptionToFailure(error);
    }
  }

  @override
  Future<List<HeatmapCell>> getSurgeHeatmap({
    required double lat,
    required double lng,
    required int gridSize,
    required double cellSize,
    required List<double> requestLats,
    required List<double> requestLngs,
  }) async {
    const surgeOffsets = [
      {'latOffset': 0.002, 'lngOffset': -0.002, 'intensity': 2.5},
      {'latOffset': -0.001, 'lngOffset': 0.003, 'intensity': 1.8},
      {'latOffset': 0.005, 'lngOffset': 0.001, 'intensity': 3.1},
    ];
    return surgeOffsets
        .map(
          (o) => HeatmapCell(
            lat: lat + (o['latOffset'] ?? 0.0),
            lng: lng + (o['lngOffset'] ?? 0.0),
            intensity: o['intensity'] ?? 0.0,
          ),
        )
        .toList();
  }
}
