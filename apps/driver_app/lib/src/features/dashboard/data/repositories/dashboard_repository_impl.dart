import 'package:driver_app/src/features/active_ride/active_ride.dart';
import 'package:driver_app/src/features/auth/domain/failures/auth_failures.dart';
import 'dart:developer' as dev;

import 'package:dio/dio.dart';
import 'package:driver_app/src/infrastructure/telemetry/driver_background_telemetry.dart';
import 'package:driver_app/src/infrastructure/session/driver_session_store.dart';
import 'package:driver_app/src/features/dashboard/data/data_sources/driver_availability_remote_data_source.dart';
import 'package:driver_app/src/features/dashboard/data/data_sources/ride_offer_remote_data_source.dart';
import 'package:driver_app/src/features/dashboard/domain/entities/driver_dashboard_stats.dart';
import 'package:driver_app/src/features/dashboard/domain/entities/driver_dispatch_snapshot.dart';
import 'package:driver_app/src/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:driver_app/src/features/active_ride/domain/repositories/driver_ride_repository.dart';
import 'package:driver_app/src/features/performance/domain/repositories/driver_performance_repository.dart';
import 'package:driver_app/src/features/ride_history/domain/repositories/driver_ride_history_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:foundation/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class DashboardRepositoryImpl implements DashboardRepository {
  final DriverPerformanceRepository _performanceRepository;
  final DriverRideHistoryRepository _rideHistoryRepository;
  final DriverAvailabilityRemoteDataSource _availabilityDataSource;
  final RideOfferRemoteDataSource _rideOfferDataSource;
  final DriverRideRepository _rideRepository;
  final DriverSessionStore _sessionService;
  final SharedPreferences _preferences;
  final DriverBackgroundTelemetry? _backgroundTelemetryService;

  DashboardRepositoryImpl({
    required DriverPerformanceRepository performanceRepository,
    required DriverRideHistoryRepository rideHistoryRepository,
    required DriverAvailabilityRemoteDataSource availabilityDataSource,
    required RideOfferRemoteDataSource rideOfferDataSource,
    required DriverRideRepository rideRepository,
    required DriverSessionStore sessionService,
    required SharedPreferences preferences,
    DriverBackgroundTelemetry? backgroundTelemetryService,
  }) : _performanceRepository = performanceRepository,
       _rideHistoryRepository = rideHistoryRepository,
       _availabilityDataSource = availabilityDataSource,
       _rideOfferDataSource = rideOfferDataSource,
       _rideRepository = rideRepository,
       _sessionService = sessionService,
       _preferences = preferences,
       _backgroundTelemetryService = backgroundTelemetryService;

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
      final result = await _rideRepository.clearDriverLocation();
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
      return const Left(
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
          ? const Right(null)
          : Left(_mapExceptionToFailure(statusError));
    }

    try {
      Failure? locationFailure;
      (await _rideRepository.publishDriverLocation(
        latitude: lat,
        longitude: lng,
      )).fold((failure) => locationFailure = failure, (_) {});
      if (locationFailure != null) {
        await _clearOnlinePresence(driverId: driverId, markServerOffline: true);
        return Left(locationFailure!);
      }

      await _availabilityDataSource.updateOnlineStatus(
        driverId: driverId,
        isOnline: true,
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
      await _clearOnlinePresence(driverId: driverId, markServerOffline: true);
      return Left(_mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, DriverDashboardStats>> getDashboardStats() async {
    try {
      final driverId = await _getDriverId();
      if (driverId.isEmpty) {
        return const Left(
          AuthFailure('Driver session is unavailable. Please sign in again.'),
        );
      }
      return (await _performanceRepository.fetchStats(driverId)).map(
        (stats) => DriverDashboardStats(
          earnings: stats.todayEarningsCentavos / 100,
          completedTrips: stats.todayCompletedTrips,
        ),
      );
    } catch (error) {
      return Left(_mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, DriverDispatchSnapshot>> getDispatchSnapshot({
    bool includeOffers = true,
    int limit = 10,
  }) async {
    try {
      final driverId = await _getDriverId();
      if (driverId.isEmpty) {
        return const Left(
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
      return tripResult.fold(
        Left.new,
        (page) => Right(
          DriverDispatchSnapshot(activeTrips: page.items, rideOffers: offers),
        ),
      );
    } catch (error) {
      return Left(_mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, void>> submitRideOffer({
    required String sessionId,
    required double farePesos,
  }) async {
    if (sessionId.trim().isEmpty || !farePesos.isFinite || farePesos <= 0) {
      return const Left(ValidationFailure('The ride offer is invalid.'));
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
          ? const Right(null)
          : const Left(ServerFailure('The ride offer was not accepted.'));
    } catch (error) {
      return Left(_mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, RideSnapshot>> fetchRide(String rideId) {
    return _rideRepository.fetchRide(rideId);
  }
}
