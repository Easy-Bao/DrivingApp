import 'package:fpdart/fpdart.dart';

import '../errors/failures.dart';
import '../models/heatmap_cell_model.dart';

abstract class DashboardRepository {
  Future<Either<Failure, double>> getTodayEarnings();

  Future<Either<Failure, int>> getTodayTrips();

  Future<Either<Failure, double>> getHoursOnline();

  Future<Either<Failure, List<HeatmapCell>>> getSurgeHeatmap({
    required double lat,
    required double lng,
    required int gridSize,
    required double cellSize,
    required List<double> requestLats,
    required List<double> requestLngs,
  });
}
