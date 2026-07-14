import 'package:fpdart/fpdart.dart';

import '../errors/failures.dart';
import '../models/heatmap_cell.dart';

/// Contract: defines what the driver dashboard feature needs from the data layer.
abstract class DashboardRepository {
  /// Returns total earnings computed for the current day.
  Future<Either<Failure, double>> getTodayEarnings();

  /// Returns count of completed trips for the current day.
  Future<Either<Failure, int>> getTodayTrips();

  /// Returns total active time spent online during the current day.
  Future<Either<Failure, double>> getHoursOnline();

  /// Returns a list of heatmap cells representing surge demand density,
  /// or [Left] with a [Failure] if the grid computation fails.
  Future<Either<Failure, List<HeatmapCell>>> getSurgeHeatmap({
    required double lat,
    required double lng,
    required int gridSize,
    required double cellSize,
    required List<double> requestLats,
    required List<double> requestLngs,
  });
}
