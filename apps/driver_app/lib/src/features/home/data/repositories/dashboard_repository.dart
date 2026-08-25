import 'dart:developer' as dev;

import 'package:dio/dio.dart';
import 'package:driver_app/src/core/services/background_telemetry_service.dart';
import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/features/activity/domain/repositories/i_driver_activity_repository.dart';
import 'package:driver_app/src/features/home/data/datasources/driver_availability_remote_data_source.dart';
import 'package:driver_app/src/features/home/data/datasources/ride_offer_remote_data_source.dart';
import 'package:driver_app/src/features/home/domain/entities/driver_dashboard_stats.dart';
import 'package:driver_app/src/features/home/domain/entities/driver_dispatch_snapshot.dart';
import 'package:driver_app/src/features/home/domain/repositories/i_dashboard_repository.dart';
import 'package:driver_app/src/features/trip/domain/repositories/i_driver_ride_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardRepository implements IDashboardRepository {
  final IDriverActivityRepository _activityRepository;
  final DriverAvailabilityRemoteDataSource _availabilityDataSource;
  final RideOfferRemoteDataSource _rideOfferDataSource;
  final IDriverRideRepository _rideRepository;
  final SecureSessionService _sessionService;
  final SharedPreferences _preferences;
  final BackgroundTelemetryService? _backgroundTelemetryService;

  DashboardRepository({
    required IDriverActivityRepository activityRepository,
    required DriverAvailabilityRemoteDataSource availabilityDataSource,
    required RideOfferRemoteDataSource rideOfferDataSource,
    required IDriverRideRepository rideRepository,
    required SecureSessionService sessionService,
    required SharedPreferences preferences,
    BackgroundTelemetryService? backgroundTelemetryService,
  }) : _activityRepository = activityRepository,
       _availabilityDataSource = availabilityDataSource,
       _rideOfferDataSource = rideOfferDataSource,
       _rideRepository = rideRepository,
       _sessionService = sessionService,
       _preferences = preferences,
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
        return const ServerFailure.withStatusCode(
          'Driver availability access is restricted.',
          403,
        );
      }
      if (statusCode == null) {
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.sendTimeout ||
            error.type == DioExceptionType.receiveTimeout) {
          return const ServerFailure.withStatusCode(
            'Driver availability request timed out.',
            504,
          );
        }
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
        return const ServerFailure.withStatusCode(
          'Driver availability endpoint was not found. Check that the API services are running.',
          404,
        );
      }
      return ServerFailure.withStatusCode(
        'Unable to update your driver availability. Please try again.',
        statusCode,
      );
    }
    if (error is ServerException) {
      if (error.statusCode == 401) {
        return const AuthFailure(
          'Session expired or unauthorized. Please sign in again.',
        );
      }
      if (error.statusCode == 403) {
        return const ServerFailure.withStatusCode(
          'Driver availability access is restricted.',
          403,
        );
      }
      if (error.statusCode == 400 || error.statusCode == 422) {
        return const ValidationFailure('Invalid request data.');
      }
      if (error.statusCode == 0) {
        return const NetworkFailure();
      }
      return ServerFailure.withStatusCode(error.message, error.statusCode);
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
      return const Left(CacheFailure('Driver ID is not registered.'));
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
        return const Left(CacheFailure('Driver ID is not registered.'));
      }
      return (await _activityRepository.fetchStats(driverId)).map(
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
        return const Left(CacheFailure('Driver ID is not registered.'));
      }
      final tripsFuture = _activityRepository.fetchTripHistory(
        driverId,
        limit: limit,
        activeOnly: true,
      );
      final offersFuture = includeOffers
          ? _rideOfferDataSource.fetchActiveBids()
          : Future<List<dynamic>>.value(const []);
      final responses = await Future.wait<dynamic>([tripsFuture, offersFuture]);
      final tripResult =
          responses[0] as Either<Failure, OffsetPage<Map<String, dynamic>>>;
      OffsetPage<Map<String, dynamic>>? tripPage;
      final Failure? tripFailure = tripResult.fold((failure) => failure, (
        page,
      ) {
        tripPage = page;
        return null;
      });
      if (tripFailure != null) return Left(tripFailure);
      final offers = (responses[1] as List<dynamic>)
          .whereType<Map>()
          .map((value) => Map<String, dynamic>.from(value))
          .toList(growable: false);
      return Right(
        DriverDispatchSnapshot(
          activeTrips: tripPage!.items,
          rideOffers: offers,
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
