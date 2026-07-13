import '../models/heatmap_cell.dart';

/// Contract: defines what the driver dashboard feature needs from the data layer.
abstract class DashboardRepository {
  /// Returns total earnings computed for the current day.
  Future<double> getTodayEarnings();

  /// Returns count of completed trips for the current day.
  Future<int> getTodayTrips();

  /// Returns total active time spent online during the current day.
  Future<double> getHoursOnline();

  /// Returns a list of heatmap cells representing passenger demand density.
  Future<List<HeatmapCell>> getSurgeHeatmap({
    required double lat,
    required double lng,
    required int gridSize,
    required double cellSize,
    required List<double> requestLats,
    required List<double> requestLngs,
  });
}
