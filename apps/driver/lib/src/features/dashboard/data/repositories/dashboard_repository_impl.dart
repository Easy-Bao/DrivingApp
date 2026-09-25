import 'package:driver/src/features/active_ride/active_ride.dart';
import 'package:driver/src/features/auth/domain/failures/auth_failures.dart';

import 'dart:async';
import 'dart:developer' as dev;

import 'package:dio/dio.dart';
import 'package:driver/src/infrastructure/telemetry/driver_background_telemetry.dart';
import 'package:driver/src/infrastructure/session/driver_session_store.dart';
import 'package:driver/src/features/dashboard/data/data_sources/driver_availability_remote_data_source.dart';
import 'package:driver/src/features/dashboard/data/data_sources/ride_offer_remote_data_source.dart';
import 'package:driver/src/features/dashboard/domain/entities/driver_dashboard_stats.dart';
import 'package:driver/src/features/dashboard/domain/entities/driver_dispatch_snapshot.dart';
import 'package:driver/src/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:driver/src/features/active_ride/domain/repositories/driver_ride_repository.dart';
import 'package:driver/src/features/performance/domain/repositories/driver_performance_repository.dart';
import 'package:driver/src/features/ride_history/domain/repositories/driver_ride_history_repository.dart';
import 'package:foundation/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class DashboardRepositoryImpl({
  required this._performanceRepository,
  required this._rideHistoryRepository,
  required this._availabilityDataSource,
  required this._rideOfferDataSource,
  required this._rideRepository,
  required this._sessionService,
  required this._preferences,
  this._backgroundTelemetryService,
}) implements DashboardRepository {
  final DriverPerformanceRepository _performanceRepository;
  final DriverRideHistoryRepository _rideHistoryRepository;
  final DriverAvailabilityRemoteDataSource _availabilityDataSource;
  final RideOfferRemoteDataSource _rideOfferDataSource;
  final DriverRideRepository _rideRepository;
  final DriverSessionStore _sessionService;
  final SharedPreferences _preferences;
  final DriverBackgroundTelemetry? _backgroundTelemetryService;

  Failure _mapExceptionToFailure(Object error) => switch (error) {
    final DioException exception => _mapDioFailure(exception),
    final ServerException exception => _mapServerFailure(exception),
    final DataParsingException exception => FailureMapper.fromException(
      exception,
      validationMessage:
          'Driver availability data is invalid. Please try again.',
    ),
    CacheException() => const AuthFailure(
      'Driver session is unavailable. Please sign in again.',
    ),
    _ => const ServerFailure(
      'Unable to update your driver availability. Please try again.',
    ),
  };

  Failure _mapDioFailure(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode == null && _isTimeout(error.type)) {
      return const ServerFailure.withStatusCode(
        'Driver availability request timed out.',
        504,
      );
    }

    return switch (statusCode) {
      401 => const AuthFailure(
        'Session expired or unauthorized. Please sign in again.',
      ),
      403 => const ServerFailure.withStatusCode(
        'Driver availability access is restricted.',
        403,
      ),
      400 || 422 => ValidationFailure(
        _safeAvailabilityMessage(error.response?.data) ??
            'The online status request was invalid. Please try again.',
      ),
      404 => const ServerFailure.withStatusCode(
        'Driver availability endpoint was not found. Check that the API services are running.',
        404,
      ),
      null => const NetworkFailure(
        'Unable to reach driver availability services. Check your connection and try again.',
      ),
      final statusCode => ServerFailure.withStatusCode(
        'Unable to update your driver availability. Please try again.',
        statusCode,
      ),
    };
  }

  Failure _mapServerFailure(ServerException error) =>
      switch (error.statusCode) {
        401 => const AuthFailure(
          'Session expired or unauthorized. Please sign in again.',
        ),
        403 => const ServerFailure.withStatusCode(
          'Driver availability access is restricted.',
          403,
        ),
        400 || 422 => const ValidationFailure('Invalid request data.'),
        0 => const NetworkFailure(),
        _ => FailureMapper.fromException(
          error,
          serverMessage:
              'Unable to update your driver availability. Please try again.',
        ),
      };

  bool _isTimeout(DioExceptionType type) => switch (type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => true,
    _ => false,
  };

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
  Future<Result<bool, Failure>> getPersistedOnlineStatus() async {
    try {
      final isOnline = await _sessionService.readDriverOnlineStatus() ?? false;
      return Ok(isOnline);
    } catch (error) {
      return Err(_mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<DateTime?, Failure>> getPersistedOnlineSince() async {
    try {
      return Ok(await _sessionService.readDriverOnlineSince());
    } catch (error) {
      return Err(_mapExceptionToFailure(error));
    }
  }

  Future<void> _clearOnlinePresence({
    required String driverId,
    required bool markServerOffline,
  }) async {
    if (markServerOffline) {
      try {
        await _availabilityDataSource.updateOnlineStatus(
          driverId: driverId,
          isOnline: false,
        );
      } catch (error) {
        dev.log('Unable to mark driver offline during cleanup: $error');
      }
    }

    try {
      final result = await _rideRepository.clearDriverLocationResult();
      result.fold(
        (failure) => dev.log(
          'Unable to remove driver location during cleanup: ${failure.message}',
        ),
        (_) {},
      );
    } catch (error) {
      dev.log('Unable to remove driver location during cleanup: $error');
    }
    try {
      await _sessionService.saveDriverOnlineStatus(false);
      await _sessionService.clearDriverOnlineSince();
    } catch (error) {
      dev.log('Unable to persist offline driver status: $error');
    }
    try {
      await _backgroundTelemetryService?.stop();
    } catch (error) {
      dev.log('Unable to stop background telemetry: $error');
    }
  }

  Future<void> _publishInitialLocation({
    required double lat,
    required double lng,
  }) async {
    if (lat == 0 && lng == 0) return;
    try {
      final result = await _rideRepository.publishDriverLocationResult(
        latitude: lat,
        longitude: lng,
      );
      result.fold(
        (failure) => dev.log(
          'Unable to publish initial driver location: ${failure.message}',
        ),
        (_) {},
      );
    } catch (error, stackTrace) {
      dev.log(
        'Unable to publish initial driver location.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _startBackgroundTelemetry() async {
    try {
      await _backgroundTelemetryService?.start();
    } catch (error, stackTrace) {
      // Online presence is already confirmed by the API. The foreground
      // heartbeat and the next background lifecycle event can retry service
      // startup without making the switch wait for native plugin work.
      dev.log(
        'Unable to start background driver telemetry.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _persistOnlineState() async {
    try {
      await _sessionService.saveDriverOnlineStatus(true);
      final onlineSince = await _sessionService.readDriverOnlineSince();
      if (onlineSince == null) {
        await _sessionService.saveDriverOnlineSince(DateTime.now().toUtc());
      }
    } catch (error) {
      dev.log('Unable to persist driver online status: $error');
    }
  }

  @override
  Future<Result<void, Failure>> updateOnlineStatus({
    required bool isOnline,
    required double lat,
    required double lng,
  }) async {
    final String driverId;
    try {
      driverId = await _getDriverId();
    } catch (error) {
      return Err(_mapExceptionToFailure(error));
    }
    if (driverId.isEmpty) {
      return const Err(
        AuthFailure('Driver session is unavailable. Please sign in again.'),
      );
    }

    if (!isOnline) {
      Object? statusError;
      try {
        await _availabilityDataSource.updateOnlineStatus(
          driverId: driverId,
          isOnline: false,
        );
      } catch (error) {
        statusError = error;
      }
      await _clearOnlinePresence(driverId: driverId, markServerOffline: false);
      return statusError == null
          ? const Ok(null)
          : Err(_mapExceptionToFailure(statusError));
    }

    try {
      await _availabilityDataSource.updateOnlineStatus(
        driverId: driverId,
        isOnline: true,
      );

      // The availability response is the user-visible transition. Location
      // delivery and native service startup are retryable telemetry work and
      // must not serialize behind the switch.
      unawaited(_publishInitialLocation(lat: lat, lng: lng));
      unawaited(_startBackgroundTelemetry());
      unawaited(_persistOnlineState());
      return const Ok(null);
    } catch (error) {
      await _clearOnlinePresence(driverId: driverId, markServerOffline: true);
      return Err(_mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<DriverDashboardStats, Failure>> getDashboardStats() async {
    try {
      final driverId = await _getDriverId();
      if (driverId.isEmpty) {
        return const Err(
          AuthFailure('Driver session is unavailable. Please sign in again.'),
        );
      }
      return (await _performanceRepository.fetchStats(driverId)).map(
        (stats) => DriverDashboardStats(
          earnings: stats.todayEarningsAmount / 100,
          completedTrips: stats.todayCompletedTrips,
        ),
      );
    } catch (error) {
      return Err(_mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<DriverDispatchSnapshot, Failure>> getDispatchSnapshot({
    bool includeOffers = true,
    int limit = 10,
  }) async {
    try {
      final driverId = await _getDriverId();
      if (driverId.isEmpty) {
        return const Err(
          AuthFailure('Driver session is unavailable. Please sign in again.'),
        );
      }
      final tripsFuture = _rideHistoryRepository.fetchTripHistory(
        driverId,
        limit: limit,
        activeOnly: true,
      );
      final offersFuture = includeOffers
          ? _rideOfferDataSource.fetchActiveBids()
          : Future.value(const <Map<String, dynamic>>[]);
      final tripResult = await tripsFuture;
      final offers = await offersFuture;
      return await tripResult.fold(
        Err.new,
        (page) => Ok(
          DriverDispatchSnapshot(activeTrips: page.items, rideOffers: offers),
        ),
      );
    } catch (error) {
      return Err(_mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<void, Failure>> submitRideOffer({
    required String sessionId,
    required double farePesos,
  }) async {
    if (sessionId.trim().isEmpty || !farePesos.isFinite || farePesos <= 0) {
      return const Err(ValidationFailure('The ride offer is invalid.'));
    }
    try {
      final accepted = await _rideOfferDataSource.placeBid(
        sessionId: sessionId,
        driverName: _preferences.getString('driver_name') ?? '',
        plateNumber: _preferences.getString('plate_number') ?? '',
        vehicleType: _preferences.getString('vehicle_type') ?? '',
        offerPrice: farePesos,
      );
      return accepted
          ? const Ok(null)
          : const Err(ServerFailure('The ride offer was not accepted.'));
    } catch (error) {
      return Err(_mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<RideSnapshot, Failure>> fetchRide(String rideId) {
    return _rideRepository.fetchRide(rideId);
  }
}
