import 'dart:developer' as dev;

import 'package:shared_core/shared_core.dart';
import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/core/services/background_telemetry_service.dart';
import 'package:driver_app/src/features/home/data/datasources/driver_remote_data_source.dart';
import 'package:driver_app/src/features/home/data/models/heatmap_cell_model.dart';
import 'package:driver_app/src/features/home/domain/repositories/i_dashboard_repository.dart';
import 'package:driver_app/src/features/trip/data/datasources/telemetry_remote_data_source.dart';
import 'package:driver_app/src/features/trip/data/datasources/trip_remote_data_source.dart';
import 'package:fpdart/fpdart.dart';

class DashboardRepository implements IDashboardRepository {
  final TripRemoteDataSource _remoteDataSource;
  final DriverRemoteDataSource _driverRemoteDataSource;
  final TelemetryRemoteDataSource _telemetryRemoteDataSource;
  final SecureSessionService _sessionService;
  final BackgroundTelemetryService? _backgroundTelemetryService;

  DashboardRepository({
    required TripRemoteDataSource remoteDataSource,
    required DriverRemoteDataSource driverRemoteDataSource,
    required TelemetryRemoteDataSource telemetryRemoteDataSource,
    required SecureSessionService sessionService,
    BackgroundTelemetryService? backgroundTelemetryService,
  }) : _remoteDataSource = remoteDataSource,
       _driverRemoteDataSource = driverRemoteDataSource,
       _telemetryRemoteDataSource = telemetryRemoteDataSource,
       _sessionService = sessionService,
       _backgroundTelemetryService = backgroundTelemetryService;

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
      return ServerFailure(error.message);
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
      return await _sessionService.readDriverId() ?? '';
    } catch (error) {
      throw CacheException(
        message: 'Failed to access secure storage session: $error',
      );
    }
  }

  @override
  Future<Either<Failure, bool>> getPersistedOnlineStatus() async {
    try {
      final isOnline = await _sessionService.readDriverOnlineStatus() ?? false;
      if (isOnline && _backgroundTelemetryService != null) {
        try {
          await _backgroundTelemetryService.start();
        } catch (error) {
          dev.log('Unable to resume background telemetry: $error');
        }
      }
      return Right(isOnline);
    } catch (error) {
      return Left(_mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, void>> updateOnlineStatus({
    required bool isOnline,
    required double lat,
    required double lng,
  }) async {
    try {
      final driverId = await _getDriverId();
      if (driverId.isEmpty) {
        return const Left(CacheFailure('Driver ID is not registered.'));
      }

      if (isOnline) {
        bool locationSent;
        try {
          locationSent = await _telemetryRemoteDataSource.sendLocationUpdate(
            driverId: driverId,
            lat: lat,
            lng: lng,
          );
        } catch (error) {
          dev.log('Unable to publish initial driver location: $error');
          return const Left(
            NetworkFailure(
              'Unable to share your location. You are not online yet.',
            ),
          );
        }
        if (!locationSent) {
          return const Left(
            NetworkFailure(
              'Unable to share your location. You are not online yet.',
            ),
          );
        }
      }
      await _driverRemoteDataSource.updateOnlineStatus(
        driverId: driverId,
        isOnline: isOnline,
        lat: lat,
        lng: lng,
      );
      try {
        await _sessionService.saveDriverOnlineStatus(isOnline);
      } catch (error) {
        dev.log('Unable to persist driver online status: $error');
      }
      final backgroundTelemetryService = _backgroundTelemetryService;
      if (backgroundTelemetryService != null) {
        try {
          if (isOnline) {
            await backgroundTelemetryService.start();
          } else {
            await backgroundTelemetryService.stop();
          }
        } catch (error) {
          dev.log('Unable to update background telemetry state: $error');
        }
      }
      return const Right(null);
    } catch (error) {
      return Left(_mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, double>> getTodayEarnings() async {
    try {
      final driverId = await _getDriverId();
      if (driverId.isEmpty) {
        return const Left(CacheFailure('Driver ID is not registered.'));
      }
      final data = await _remoteDataSource.fetchStats(driverId);
      return Right((data['todayEarnings'] as num?)?.toDouble() ?? 0.0);
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
      final data = await _remoteDataSource.fetchStats(driverId);
      return Right((data['todayTrips'] as int?) ?? 0);
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
      final data = await _remoteDataSource.fetchStats(driverId);
      return Right((data['hoursOnline'] as num?)?.toDouble() ?? 0.0);
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
    // Surge cells must come from a server pricing/dispatch response. Until
    // that endpoint exists, an empty layer is safer than fabricated demand.
    return const Right(<HeatmapCell>[]);
  }
}
