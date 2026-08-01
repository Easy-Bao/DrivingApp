import 'package:core_models/CoreModels.dart';
import 'package:driver_app/src/Features/Home/Data/Models/HeatmapCellModel.dart';
import 'package:fpdart/fpdart.dart';

abstract class IDashboardRepository {
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
