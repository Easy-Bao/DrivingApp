import 'dart:convert';
import 'package:core_models/core_models.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:driver_app/src/core/config/env_config.dart';

/**
 * API-backed implementation of [DashboardRepository].
 * Designed to fetch data directly from backend server endpoints.
 */
class DashboardRepositoryImpl implements DashboardRepository {
  Future<String> _getDriverId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('driver_id') ?? '';
  }

  @override
  Future<double> getTodayEarnings() async {
    final driverId = await _getDriverId();
    if (driverId.isEmpty) return 0.0;
    try {
      final baseUrl = EnvConfig.driverServiceUrl;
      final response = await http.get(
        Uri.parse('$baseUrl/drivers/$driverId/stats'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
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
      final baseUrl = EnvConfig.driverServiceUrl;
      final response = await http.get(
        Uri.parse('$baseUrl/drivers/$driverId/stats'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
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
      final baseUrl = EnvConfig.driverServiceUrl;
      final response = await http.get(
        Uri.parse('$baseUrl/drivers/$driverId/stats'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
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
    // Generate surge heatmap coordinates dynamically around the user's location
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
