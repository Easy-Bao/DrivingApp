import 'dart:developer' as dev;

import 'package:dio/dio.dart';
import 'package:shared_core/shared_core.dart';
import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/core/services/background_telemetry_service.dart';
import 'package:driver_app/src/features/home/data/datasources/driver_remote_data_source.dart';
import 'package:driver_app/src/features/home/data/models/heatmap_cell_model.dart';
import 'package:driver_app/src/features/home/domain/entities/driver_dashboard_stats.dart';
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
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 401) {
        return const AuthFailure(
          'Session expired or unauthorized. Please sign in again.',
        );
      }
      if (statusCode == 403) {
        final profileMessage = _safeAvailabilityMessage(error.response?.data);
        if (profileMessage != null) return ServerFailure(profileMessage);
        return const AuthFailure(
          'This account is not authorized to change driver availability.',
        );
      }
      if (statusCode == null) {
        return const NetworkFailure(
          'Unable to reach driver availability services. Check your connection and try again.',
        );
      }
      if (statusCode == 400 || statusCode == 422) {
        return ValidationFailure(
          _safeAvailabilityMessage(error.response?.data) ??
              'The online status request was invalid. Please try again.',
        );
      }
      if (statusCode == 404) {
        return const ServerFailure(
          'Driver availability endpoint was not found. Check that the API services are running.',
        );
      }
      return const ServerFailure(
        'Unable to update your driver availability. Please try again.',
      );
    }
    if (error is ServerException) {
      if (error.statusCode == 401) {
        return const AuthFailure(
          'Session expired or unauthorized. Please sign in again.',
        );
      }
      if (error.statusCode == 403) {
        return const AuthFailure(
          'This account is not authorized to change driver availability.',
        );
      }
      if (error.statusCode == 400 || error.statusCode == 422) {
        return const ValidationFailure('Invalid request data.');
      }
      if (error.statusCode == 0) {
        return NetworkFailure(error.message);
      }
      return ServerFailure(error.message);
    }
    if (error is DataParsingException) {
      return ValidationFailure(error.message);
    }
    if (error is CacheException) {
      return CacheFailure(error.message);
    }
    return const ServerFailure(
      'Unable to update your driver availability. Please try again.',
    );
  }

  String? _safeAvailabilityMessage(Object? responseData) {
    if (responseData is! Map) return null;
    final rawMessage = responseData['error'] ?? responseData['message'];
    if (rawMessage is! String) return null;

    return switch (rawMessage.trim().toLowerCase()) {
      'is_online is required' || 'invalid online status' =>
        'The online status request was invalid. Please try again.',
      'driver profile required' =>
        'Your account is not configured as a driver.',
      _ => null,
    };
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
      return Right(isOnline);
    } catch (error) {
      return Left(_mapExceptionToFailure(error));
    }
  }

  Future<void> _clearOnlinePresence({
    required String driverId,
    required double lat,
    required double lng,
    required bool markServerOffline,
  }) async {
    if (markServerOffline) {
      try {
        await _driverRemoteDataSource.updateOnlineStatus(
          driverId: driverId,
          isOnline: false,
          lat: lat,
          lng: lng,
        );
      } catch (error) {
        dev.log('Unable to mark driver offline during cleanup: $error');
      }
    }

    try {
      await _telemetryRemoteDataSource.removeLocation();
    } catch (error) {
      dev.log('Unable to remove driver location during cleanup: $error');
    }
    try {
      await _sessionService.saveDriverOnlineStatus(false);
    } catch (error) {
      dev.log('Unable to persist offline driver status: $error');
    }
    try {
      await _backgroundTelemetryService?.stop();
    } catch (error) {
      dev.log('Unable to stop background telemetry: $error');
    }
  }

  @override
  Future<Either<Failure, void>> updateOnlineStatus({
    required bool isOnline,
    required double lat,
    required double lng,
  }) async {
    final String driverId;
    try {
      driverId = await _getDriverId();
    } catch (error) {
      return Left(_mapExceptionToFailure(error));
    }
    if (driverId.isEmpty) {
      return const Left(CacheFailure('Driver ID is not registered.'));
    }

    if (!isOnline) {
      Object? statusError;
      try {
        await _driverRemoteDataSource.updateOnlineStatus(
          driverId: driverId,
          isOnline: false,
          lat: lat,
          lng: lng,
        );
      } catch (error) {
        statusError = error;
      }
      await _clearOnlinePresence(
        driverId: driverId,
        lat: lat,
        lng: lng,
        markServerOffline: false,
      );
      return statusError == null
          ? const Right(null)
          : Left(_mapExceptionToFailure(statusError));
    }

    try {
      final locationSent = await _telemetryRemoteDataSource.sendLocationUpdate(
        lat: lat,
        lng: lng,
      );
      if (!locationSent) {
        await _clearOnlinePresence(
          driverId: driverId,
          lat: lat,
          lng: lng,
          markServerOffline: true,
        );
        return const Left(
          NetworkFailure(
            'Unable to share your location. You are not online yet.',
          ),
        );
      }

      await _driverRemoteDataSource.updateOnlineStatus(
        driverId: driverId,
        isOnline: true,
        lat: lat,
        lng: lng,
      );

      try {
        await _backgroundTelemetryService?.start();
      } catch (error) {
        // Foreground telemetry is already active, so an optional background
        // service must never invalidate a live driver's availability.
        dev.log(
          'Optional background telemetry was unavailable; foreground telemetry remains active: $error',
        );
      }

      try {
        await _sessionService.saveDriverOnlineStatus(true);
      } catch (error) {
        dev.log('Unable to persist driver online status: $error');
      }
      return const Right(null);
    } catch (error) {
      await _clearOnlinePresence(
        driverId: driverId,
        lat: lat,
        lng: lng,
        markServerOffline: true,
      );
      return Left(_mapExceptionToFailure(error));
    }
  }

  num? _readFiniteNumber(Map<String, dynamic> values, List<String> keys) {
    for (final key in keys) {
      final value = values[key];
      if (value is num && value.isFinite) return value;
    }
    return null;
  }

  @override
  Future<Either<Failure, DriverDashboardStats>> getDashboardStats() async {
    try {
      final driverId = await _getDriverId();
      if (driverId.isEmpty) {
        return const Left(CacheFailure('Driver ID is not registered.'));
      }
      final data = await _remoteDataSource.fetchStats(driverId);
      final earningsCentavos = _readFiniteNumber(data, const [
        'today_earnings_centavos',
      ]);
      final completedTrips = _readFiniteNumber(data, const [
        'today_completed_trips',
      ]);
      if (earningsCentavos == null ||
          earningsCentavos < 0 ||
          completedTrips == null ||
          completedTrips < 0 ||
          completedTrips != completedTrips.roundToDouble()) {
        throw DataParsingException(
          message: 'Driver statistics response is incomplete.',
        );
      }
      return Right(
        DriverDashboardStats(
          earnings: earningsCentavos / 100,
          completedTrips: completedTrips.toInt(),
        ),
      );
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
