import 'package:driver_app/src/features/auth/domain/failures/auth_failures.dart';
import 'package:dio/dio.dart';
import 'package:driver_app/src/infrastructure/telemetry/driver_background_telemetry.dart';
import 'package:driver_app/src/infrastructure/session/driver_session_store.dart';
import 'package:driver_app/src/features/activity/domain/entities/driver_activity_stats.dart';
import 'package:driver_app/src/features/activity/domain/repositories/i_driver_activity_repository.dart';
import 'package:driver_app/src/features/dashboard/data/data_sources/driver_availability_remote_data_source.dart';
import 'package:driver_app/src/features/dashboard/data/data_sources/ride_offer_remote_data_source.dart';
import 'package:driver_app/src/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:driver_app/src/features/dashboard/domain/entities/driver_dashboard_stats.dart';
import 'package:driver_app/src/features/active_ride/domain/repositories/i_driver_ride_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:foundation/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDriverAvailabilityRemoteDataSource extends Mock
    implements DriverAvailabilityRemoteDataSource {}

class MockDriverActivityRepository extends Mock
    implements IDriverActivityRepository {}

class MockSecureSessionService extends Mock implements DriverSessionStore {}

class MockBackgroundTelemetryService extends Mock
    implements DriverBackgroundTelemetry {}

class MockRideOfferRemoteDataSource extends Mock
    implements RideOfferRemoteDataSource {}

class MockDriverRideRepository extends Mock implements IDriverRideRepository {}

late SharedPreferences _preferences;
late MockDriverActivityRepository _activityRepository;
late MockRideOfferRemoteDataSource _rideOfferDataSource;
late MockDriverRideRepository _rideRepository;

DashboardRepository _buildRepository({
  required DriverAvailabilityRemoteDataSource availabilityDataSource,
  required DriverSessionStore sessionService,
  DriverBackgroundTelemetry? backgroundTelemetryService,
}) {
  return DashboardRepository(
    activityRepository: _activityRepository,
    availabilityDataSource: availabilityDataSource,
    rideOfferDataSource: _rideOfferDataSource,
    rideRepository: _rideRepository,
    sessionService: sessionService,
    preferences: _preferences,
    backgroundTelemetryService: backgroundTelemetryService,
  );
}

DioException _httpFailure({required int statusCode, Object? data}) {
  return DioException(
    requestOptions: RequestOptions(path: '/api/v1/drivers/42/online'),
    response: Response<Object?>(
      requestOptions: RequestOptions(path: '/api/v1/drivers/42/online'),
      statusCode: statusCode,
      data: data,
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _preferences = await SharedPreferences.getInstance();
    _activityRepository = MockDriverActivityRepository();
    _rideOfferDataSource = MockRideOfferRemoteDataSource();
    _rideRepository = MockDriverRideRepository();
  });

  test(
    'maps completed trip statistics from the server contract once',
    () async {
      final availabilityDataSource = MockDriverAvailabilityRemoteDataSource();
      final sessionService = MockSecureSessionService();

      when(
        () => sessionService.readDriverId(),
      ).thenAnswer((_) async => 'driver-42');
      when(() => _activityRepository.fetchStats('driver-42')).thenAnswer(
        (_) async => const Right(
          DriverActivityStats(
            todayEarningsCentavos: 2817,
            todayCompletedTrips: 1,
            totalTrips: 6,
            completedTrips: 6,
            totalEarningsCentavos: 2817,
            averageRating: 5,
          ),
        ),
      );

      final repository = _buildRepository(
        availabilityDataSource: availabilityDataSource,
        sessionService: sessionService,
      );

      final result = await repository.getDashboardStats();

      expect(
        result,
        const Right<Failure, DriverDashboardStats>(
          DriverDashboardStats(earnings: 28.17, completedTrips: 1),
        ),
      );
      verify(() => _activityRepository.fetchStats('driver-42')).called(1);
    },
  );

  test(
    'reports an incomplete local session as an authentication failure',
    () async {
      final availabilityDataSource = MockDriverAvailabilityRemoteDataSource();
      final sessionService = MockSecureSessionService();

      when(() => sessionService.readDriverId()).thenAnswer((_) async => null);

      final repository = _buildRepository(
        availabilityDataSource: availabilityDataSource,
        sessionService: sessionService,
      );

      final result = await repository.getDashboardStats();

      expect(
        result,
        const Left<Failure, DriverDashboardStats>(
          AuthFailure('Driver session is unavailable. Please sign in again.'),
        ),
      );
      verifyNever(() => _activityRepository.fetchStats(any()));
    },
  );

  test('publishes the initial driver location when going online', () async {
    final availabilityDataSource = MockDriverAvailabilityRemoteDataSource();
    final sessionService = MockSecureSessionService();

    when(
      () => sessionService.readDriverId(),
    ).thenAnswer((_) async => 'driver-42');
    when(
      () => availabilityDataSource.updateOnlineStatus(
        driverId: 'driver-42',
        isOnline: true,
      ),
    ).thenAnswer((_) async {});
    when(
      () => _rideRepository.publishDriverLocation(
        latitude: 7.828,
        longitude: 123.434,
      ),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => sessionService.saveDriverOnlineStatus(true),
    ).thenAnswer((_) async {});

    final repository = _buildRepository(
      availabilityDataSource: availabilityDataSource,
      sessionService: sessionService,
    );

    final result = await repository.updateOnlineStatus(
      isOnline: true,
      lat: 7.828,
      lng: 123.434,
    );

    expect(result, const Right<Failure, void>(null));
    verify(
      () => _rideRepository.publishDriverLocation(
        latitude: 7.828,
        longitude: 123.434,
      ),
    ).called(1);
  });

  test(
    'does not mark the driver online when initial location publishing fails',
    () async {
      final availabilityDataSource = MockDriverAvailabilityRemoteDataSource();
      final sessionService = MockSecureSessionService();

      when(
        () => sessionService.readDriverId(),
      ).thenAnswer((_) async => 'driver-42');
      when(
        () => _rideRepository.publishDriverLocation(
          latitude: 7.828,
          longitude: 123.434,
        ),
      ).thenAnswer(
        (_) async => const Left(
          NetworkFailure(
            'Unable to share your location. You are not online yet.',
          ),
        ),
      );
      when(
        () => availabilityDataSource.updateOnlineStatus(
          driverId: 'driver-42',
          isOnline: false,
        ),
      ).thenAnswer((_) async {});
      when(
        () => _rideRepository.clearDriverLocation(),
      ).thenAnswer((_) async => const Right(null));
      when(
        () => sessionService.saveDriverOnlineStatus(false),
      ).thenAnswer((_) async {});

      final repository = _buildRepository(
        availabilityDataSource: availabilityDataSource,
        sessionService: sessionService,
      );

      final result = await repository.updateOnlineStatus(
        isOnline: true,
        lat: 7.828,
        lng: 123.434,
      );

      expect(
        result,
        const Left<Failure, void>(
          NetworkFailure(
            'Unable to share your location. You are not online yet.',
          ),
        ),
      );
      verify(
        () => availabilityDataSource.updateOnlineStatus(
          driverId: 'driver-42',
          isOnline: false,
        ),
      ).called(1);
      verifyNever(
        () => availabilityDataSource.updateOnlineStatus(
          driverId: 'driver-42',
          isOnline: true,
        ),
      );
      verify(() => _rideRepository.clearDriverLocation()).called(1);
      verify(() => sessionService.saveDriverOnlineStatus(false)).called(1);
    },
  );

  test(
    'keeps the driver online when optional background telemetry cannot start',
    () async {
      final availabilityDataSource = MockDriverAvailabilityRemoteDataSource();
      final sessionService = MockSecureSessionService();
      final backgroundService = MockBackgroundTelemetryService();

      when(
        () => sessionService.readDriverId(),
      ).thenAnswer((_) async => 'driver-42');
      when(
        () => _rideRepository.publishDriverLocation(
          latitude: 7.828,
          longitude: 123.434,
        ),
      ).thenAnswer((_) async => const Right(null));
      when(
        () => availabilityDataSource.updateOnlineStatus(
          driverId: 'driver-42',
          isOnline: true,
        ),
      ).thenAnswer((_) async {});
      when(
        () => sessionService.saveDriverOnlineStatus(true),
      ).thenAnswer((_) async {});
      when(
        () => backgroundService.start(),
      ).thenThrow(StateError('not configured'));

      final repository = _buildRepository(
        availabilityDataSource: availabilityDataSource,
        sessionService: sessionService,
        backgroundTelemetryService: backgroundService,
      );

      final result = await repository.updateOnlineStatus(
        isOnline: true,
        lat: 7.828,
        lng: 123.434,
      );

      expect(result, const Right<Failure, void>(null));
      verify(() => backgroundService.start()).called(1);
      verifyNever(
        () => availabilityDataSource.updateOnlineStatus(
          driverId: 'driver-42',
          isOnline: false,
        ),
      );
      verifyNever(() => _rideRepository.clearDriverLocation());
      verify(() => sessionService.saveDriverOnlineStatus(true)).called(1);
    },
  );

  test('removes the driver location when going offline', () async {
    final availabilityDataSource = MockDriverAvailabilityRemoteDataSource();
    final sessionService = MockSecureSessionService();

    when(
      () => sessionService.readDriverId(),
    ).thenAnswer((_) async => 'driver-42');
    when(
      () => availabilityDataSource.updateOnlineStatus(
        driverId: 'driver-42',
        isOnline: false,
      ),
    ).thenAnswer((_) async {});
    when(
      () => _rideRepository.clearDriverLocation(),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => sessionService.saveDriverOnlineStatus(false),
    ).thenAnswer((_) async {});

    final repository = _buildRepository(
      availabilityDataSource: availabilityDataSource,
      sessionService: sessionService,
    );

    final result = await repository.updateOnlineStatus(
      isOnline: false,
      lat: 7.828,
      lng: 123.434,
    );

    expect(result, const Right<Failure, void>(null));
    verify(() => _rideRepository.clearDriverLocation()).called(1);
  });

  test(
    'keeps the server error actionable when availability update fails',
    () async {
      final availabilityDataSource = MockDriverAvailabilityRemoteDataSource();
      final sessionService = MockSecureSessionService();

      when(
        () => sessionService.readDriverId(),
      ).thenAnswer((_) async => 'driver-42');
      when(
        () => _rideRepository.publishDriverLocation(
          latitude: 7.828,
          longitude: 123.434,
        ),
      ).thenAnswer((_) async => const Right(null));
      when(
        () => availabilityDataSource.updateOnlineStatus(
          driverId: 'driver-42',
          isOnline: true,
        ),
      ).thenThrow(
        _httpFailure(
          statusCode: 400,
          data: <String, dynamic>{'error': 'is_online is required'},
        ),
      );
      when(
        () => availabilityDataSource.updateOnlineStatus(
          driverId: 'driver-42',
          isOnline: false,
        ),
      ).thenAnswer((_) async {});
      when(
        () => _rideRepository.clearDriverLocation(),
      ).thenAnswer((_) async => const Right(null));
      when(
        () => sessionService.saveDriverOnlineStatus(false),
      ).thenAnswer((_) async {});

      final repository = _buildRepository(
        availabilityDataSource: availabilityDataSource,
        sessionService: sessionService,
      );

      final result = await repository.updateOnlineStatus(
        isOnline: true,
        lat: 7.828,
        lng: 123.434,
      );

      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<ValidationFailure>());
        expect(
          failure.message,
          'The online status request was invalid. Please try again.',
        );
      }, (_) => fail('Expected availability update to fail.'));
      verify(() => _rideRepository.clearDriverLocation()).called(1);
      verify(() => sessionService.saveDriverOnlineStatus(false)).called(1);
    },
  );
}
