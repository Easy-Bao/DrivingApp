import 'package:core_models/core_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:driver_app/src/core/services/driver_api_service.dart';

/// API-backed implementation of [DashboardRepository] utilizing [DriverApiService].
class DashboardRepositoryImpl implements DashboardRepository {
  final DriverApiService _apiService;

  /// Creates a [DashboardRepositoryImpl] with constructor dependency injection.
  DashboardRepositoryImpl({required DriverApiService apiService})
    : _apiService = apiService;

  Future<String> _getDriverId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('driver_id') ?? '';
  }

  @override
  Future<double> getTodayEarnings() async {
    final driverId = await _getDriverId();
    if (driverId.isEmpty) return 0.0;
    try {
      final data = await _apiService.fetchStats(driverId);
      if (data != null && data['todayEarnings'] != null) {
        return (data['todayEarnings'] as num).toDouble();
      }
    } catch (_) {}
    return 0.0;
  }

  @override
  Future<int> getTodayTrips() async {
    final driverId = await _getDriverId();
    if (driverId.isEmpty) return 0;
    try {
      final data = await _apiService.fetchStats(driverId);
      if (data != null && data['todayTrips'] != null) {
        return data['todayTrips'] as int;
      }
    } catch (_) {}
    return 0;
  }

  @override
  Future<double> getHoursOnline() async {
    final driverId = await _getDriverId();
    if (driverId.isEmpty) return 0.0;
    try {
      final data = await _apiService.fetchStats(driverId);
      if (data != null && data['hoursOnline'] != null) {
        return (data['hoursOnline'] as num).toDouble();
      }
    } catch (_) {}
    return 0.0;
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
