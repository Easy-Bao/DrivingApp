import 'package:shared_core/shared_core.dart';
import 'package:driver_app/src/features/home/data/models/heatmap_cell_model.dart';
import 'package:driver_app/src/features/home/domain/entities/driver_dashboard_stats.dart';
import 'package:fpdart/fpdart.dart';

abstract class IDashboardRepository {
  Future<Either<Failure, bool>> getPersistedOnlineStatus();

  Future<Either<Failure, void>> updateOnlineStatus({
    required bool isOnline,
    required double lat,
    required double lng,
  });

  Future<Either<Failure, DriverDashboardStats>> getDashboardStats();

  Future<Either<Failure, List<HeatmapCell>>> getSurgeHeatmap({
    required double lat,
    required double lng,
    required int gridSize,
    required double cellSize,
    required List<double> requestLats,
    required List<double> requestLngs,
  });
}
