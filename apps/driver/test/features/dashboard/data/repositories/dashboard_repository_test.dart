import 'package:driver/src/features/auth/domain/failures/auth_failures.dart';
import 'package:dio/dio.dart';
import 'package:driver/src/infrastructure/telemetry/driver_background_telemetry.dart';
import 'package:driver/src/infrastructure/session/driver_session_store.dart';
import 'package:driver/src/features/performance/domain/entities/driver_performance_stats.dart';
import 'package:driver/src/features/performance/domain/repositories/driver_performance_repository.dart';
import 'package:driver/src/features/dashboard/data/data_sources/driver_availability_remote_data_source.dart';
import 'package:driver/src/features/dashboard/data/data_sources/ride_offer_remote_data_source.dart';
import 'package:driver/src/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:driver/src/features/dashboard/domain/entities/driver_dashboard_stats.dart';
import 'package:driver/src/features/active_ride/domain/repositories/driver_ride_repository.dart';
import 'package:driver/src/features/ride_history/domain/repositories/driver_ride_history_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:foundation/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAvailabilityRemoteDataSource extends Mock
    implements AvailabilityRemoteDataSource {}

class MockPerformanceRepository extends Mock implements PerformanceRepository {}

class MockRideHistoryRepository extends Mock implements RideHistoryRepository {}

class MockSecureSessionService extends Mock implements SessionStore {}

class MockBackgroundTelemetryService extends Mock
    implements BackgroundTelemetry {}

class MockRideOfferRemoteDataSource extends Mock
    implements RideOfferRemoteDataSource {}

class MockRideRepository extends Mock implements RideRepository {}

late SharedPreferences _preferences;
late MockPerformanceRepository _performanceRepository;
late MockRideHistoryRepository _rideHistoryRepository;
late MockRideOfferRemoteDataSource _rideOfferDataSource;
late MockRideRepository _rideRepository;

DashboardRepositoryImpl _buildRepository({
  required AvailabilityRemoteDataSource availabilityDataSource,
  required SessionStore sessionService,
  BackgroundTelemetry? backgroundTelemetryService,
  DateTime Function()? now,
  Duration? maxInactivityDuration,
}) {
  return DashboardRepositoryImpl(
    performanceRepository: _performanceRepository,
    rideHistoryRepository: _rideHistoryRepository,
    availabilityDataSource: availabilityDataSource,
    rideOfferDataSource: _rideOfferDataSource,
    rideRepository: _rideRepository,
    sessionService: sessionService,
    preferences: _preferences,
    backgroundTelemetryService: backgroundTelemetryService,
    now: now,
    maxInactivityDuration: maxInactivityDuration,
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
    _performanceRepository = MockPerformanceRepository();
    _rideHistoryRepository = MockRideHistoryRepository();
    _rideOfferDataSource = MockRideOfferRemoteDataSource();
    _rideRepository = MockRideRepository();
  });

  test(
    'maps completed trip statistics from the server contract once',
    () async {
      final availabilityDataSource = MockAvailabilityRemoteDataSource();
      final sessionService = MockSecureSessionService();

      when(() => sessionService.readDriverId())
          .thenAnswer((_) async => 'driver-42');
      when(() => _performanceRepository.fetchStats('driver-42')).thenAnswer(
        (_) async => const Ok(
          PerformanceStats(
            todayEarningsAmount: 2817,
            todayCompletedTrips: 1,
            totalTrips: 6,
            completedTrips: 6,
            totalEarningsAmount: 2817,
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
        const Ok<DashboardStats, Failure>(
          DashboardStats(earnings: 28.17, completedTrips: 1),
        ),
      );
      verify(() => _performanceRepository.fetchStats('driver-42')).called(1);
    },
  );

  test('maps one active ride from the active-history response', () async {
    final availabilityDataSource = MockAvailabilityRemoteDataSource();
    final sessionService = MockSecureSessionService();

    when(() => sessionService.readDriverId())
        .thenAnswer((_) async => 'driver-42');
    when(
      () => _rideHistoryRepository.fetchTripHistory(
        'driver-42',
        limit: 10,
        activeOnly: true,
      ),
    ).thenAnswer(
      (_) async => const Ok(
        OffsetPage(
          items: [
            {
              'id': 'ride-42',
              'status': 'in_transit',
              'pickup_name': 'Central Station',
              'dropoff_name': 'Market Road',
              'fare_amount': 14500,
            },
          ],
          hasMore: false,
          nextOffset: null,
        ),
      ),
    );
    when(() => _rideOfferDataSource.fetchActiveBids())
        .thenAnswer((_) async => const []);

    final repository = _buildRepository(
      availabilityDataSource: availabilityDataSource,
      sessionService: sessionService,
    );

    final result = await repository.getDispatchSnapshot();

    expect(
      result.fold(
        (failure) => failure.message,
        (snapshot) => snapshot.activeRide?.id,
      ),
      'ride-42',
    );
    verify(
      () => _rideHistoryRepository.fetchTripHistory(
        'driver-42',
        limit: 10,
        activeOnly: true,
      ),
    ).called(1);
  });

  test('retains all active bookings in the dispatch snapshot', () async {
    final availabilityDataSource = MockAvailabilityRemoteDataSource();
    final sessionService = MockSecureSessionService();

    when(() => sessionService.readDriverId())
        .thenAnswer((_) async => 'driver-42');
    when(
      () => _rideHistoryRepository.fetchTripHistory(
        'driver-42',
        limit: 10,
        activeOnly: true,
      ),
    ).thenAnswer(
      (_) async => const Ok(
        OffsetPage(
          items: [
            {'id': 'ride-1', 'status': 'accepted'},
            {'id': 'ride-2', 'status': 'in_transit'},
          ],
          hasMore: false,
          nextOffset: null,
        ),
      ),
    );
    when(() => _rideOfferDataSource.fetchActiveBids())
        .thenAnswer((_) async => const []);

    final repository = _buildRepository(
      availabilityDataSource: availabilityDataSource,
      sessionService: sessionService,
    );

    final result = await repository.getDispatchSnapshot();

    expect(
      result.fold(
        (failure) => failure.message,
        (snapshot) => snapshot.activeRides.map((ride) => ride.id).toList(),
      ),
      ['ride-1', 'ride-2'],
    );
  });

  test(
    'reports an incomplete local session as an authentication failure',
    () async {
      final availabilityDataSource = MockAvailabilityRemoteDataSource();
      final sessionService = MockSecureSessionService();

      when(() => sessionService.readDriverId()).thenAnswer((_) async => null);

      final repository = _buildRepository(
        availabilityDataSource: availabilityDataSource,
        sessionService: sessionService,
      );

      final result = await repository.getDashboardStats();

      expect(
        result,
        const Err<DashboardStats, Failure>(
          AuthFailure('Driver session is unavailable. Please sign in again.'),
        ),
      );
      verifyNever(() => _performanceRepository.fetchStats(any()));
    },
  );

  test('confirms availability without blocking on initial telemetry', () async {
    final availabilityDataSource = MockAvailabilityRemoteDataSource();
    final sessionService = MockSecureSessionService();

    when(() => sessionService.readDriverId())
        .thenAnswer((_) async => 'driver-42');
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
    ).thenAnswer((_) async => const Ok(null));
    when(() => sessionService.saveDriverOnlineStatus(true))
        .thenAnswer((_) async {});

    final repository = _buildRepository(
      availabilityDataSource: availabilityDataSource,
      sessionService: sessionService,
    );

    final result = await repository.updateOnlineStatus(
      isOnline: true,
      lat: 7.828,
      lng: 123.434,
    );

    expect(result, const Ok<void, Failure>(null));
    await Future<void>.delayed(Duration.zero);
    verify(
      () => _rideRepository.publishDriverLocation(
        latitude: 7.828,
        longitude: 123.434,
      ),
    ).called(1);
    verify(() => sessionService.saveDriverOnlineStatus(true)).called(1);
  });

  test(
    'keeps the driver online when initial telemetry fails so it can retry',
    () async {
      final availabilityDataSource = MockAvailabilityRemoteDataSource();
      final sessionService = MockSecureSessionService();

      when(() => sessionService.readDriverId())
          .thenAnswer((_) async => 'driver-42');
      when(
        () => _rideRepository.publishDriverLocation(
          latitude: 7.828,
          longitude: 123.434,
        ),
      ).thenAnswer(
        (_) async => const Err(
          NetworkFailure(
            'Unable to share your location. You are not online yet.',
          ),
        ),
      );
      when(
        () => availabilityDataSource.updateOnlineStatus(
          driverId: 'driver-42',
          isOnline: true,
        ),
      ).thenAnswer((_) async {});
      when(
        () => availabilityDataSource.updateOnlineStatus(
          driverId: 'driver-42',
          isOnline: false,
        ),
      ).thenAnswer((_) async {});
      when(() => _rideRepository.clearDriverLocation())
          .thenAnswer((_) async => const Ok(null));
      when(() => sessionService.saveDriverOnlineStatus(false))
          .thenAnswer((_) async {});

      final repository = _buildRepository(
        availabilityDataSource: availabilityDataSource,
        sessionService: sessionService,
      );

      final result = await repository.updateOnlineStatus(
        isOnline: true,
        lat: 7.828,
        lng: 123.434,
      );

      expect(result, const Ok<void, Failure>(null));
      await Future<void>.delayed(Duration.zero);
      verify(
        () => availabilityDataSource.updateOnlineStatus(
          driverId: 'driver-42',
          isOnline: true,
        ),
      ).called(1);
      verifyNever(
        () => availabilityDataSource.updateOnlineStatus(
          driverId: 'driver-42',
          isOnline: false,
        ),
      );
    },
  );

  test('does not make native telemetry startup block going online', () async {
    final availabilityDataSource = MockAvailabilityRemoteDataSource();
    final sessionService = MockSecureSessionService();
    final backgroundService = MockBackgroundTelemetryService();

    when(() => sessionService.readDriverId())
        .thenAnswer((_) async => 'driver-42');
    when(
      () => _rideRepository.publishDriverLocation(
        latitude: 7.828,
        longitude: 123.434,
      ),
    ).thenAnswer((_) async => const Ok(null));
    when(
      () => availabilityDataSource.updateOnlineStatus(
        driverId: 'driver-42',
        isOnline: true,
      ),
    ).thenAnswer((_) async {});
    when(() => sessionService.saveDriverOnlineStatus(true))
        .thenAnswer((_) async {});
    when(() => backgroundService.start())
        .thenThrow(StateError('not configured'));

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

    expect(result, const Ok<void, Failure>(null));
    await Future<void>.delayed(Duration.zero);
    verify(() => backgroundService.start()).called(1);
    verifyNever(
      () => availabilityDataSource.updateOnlineStatus(
        driverId: 'driver-42',
        isOnline: false,
      ),
    );
    verify(() => sessionService.saveDriverOnlineStatus(true)).called(1);
  });

  test('persists online state before starting background telemetry', () async {
    final availabilityDataSource = MockAvailabilityRemoteDataSource();
    final sessionService = MockSecureSessionService();
    final backgroundService = MockBackgroundTelemetryService();
    final callOrder = <String>[];

    when(() => sessionService.readDriverId())
        .thenAnswer((_) async => 'driver-42');
    when(
      () => availabilityDataSource.updateOnlineStatus(
        driverId: 'driver-42',
        isOnline: true,
      ),
    ).thenAnswer((_) async {});
    when(() => sessionService.saveDriverOnlineStatus(true))
        .thenAnswer((_) async {
          callOrder.add('persist');
        });
    when(() => backgroundService.start()).thenAnswer((_) async {
      callOrder.add('start_telemetry');
    });

    final repository = _buildRepository(
      availabilityDataSource: availabilityDataSource,
      sessionService: sessionService,
      backgroundTelemetryService: backgroundService,
    );

    final result = await repository.updateOnlineStatus(
      isOnline: true,
      lat: 0,
      lng: 0,
    );

    expect(result, const Ok<void, Failure>(null));
    await Future<void>.delayed(Duration.zero);
    expect(callOrder, ['persist', 'start_telemetry']);
  });

  test('removes the driver location when going offline', () async {
    final availabilityDataSource = MockAvailabilityRemoteDataSource();
    final sessionService = MockSecureSessionService();

    when(() => sessionService.readDriverId())
        .thenAnswer((_) async => 'driver-42');
    when(
      () => availabilityDataSource.updateOnlineStatus(
        driverId: 'driver-42',
        isOnline: false,
      ),
    ).thenAnswer((_) async {});
    when(() => _rideRepository.clearDriverLocation())
        .thenAnswer((_) async => const Ok(null));
    when(() => sessionService.saveDriverOnlineStatus(false))
        .thenAnswer((_) async {});

    final repository = _buildRepository(
      availabilityDataSource: availabilityDataSource,
      sessionService: sessionService,
    );

    final result = await repository.updateOnlineStatus(
      isOnline: false,
      lat: 7.828,
      lng: 123.434,
    );

    expect(result, const Ok<void, Failure>(null));
    verify(() => _rideRepository.clearDriverLocation()).called(1);
  });

  test('explains that an active ride blocks going offline', () async {
    final availabilityDataSource = MockAvailabilityRemoteDataSource();
    final sessionService = MockSecureSessionService();

    when(() => sessionService.readDriverId())
        .thenAnswer((_) async => 'driver-42');
    when(
      () => availabilityDataSource.updateOnlineStatus(
        driverId: 'driver-42',
        isOnline: false,
      ),
    ).thenThrow(_httpFailure(statusCode: 409));
    when(() => _rideRepository.clearDriverLocation())
        .thenAnswer((_) async => const Ok(null));
    when(() => sessionService.saveDriverOnlineStatus(false))
        .thenAnswer((_) async {});

    final repository = _buildRepository(
      availabilityDataSource: availabilityDataSource,
      sessionService: sessionService,
    );

    final result = await repository.updateOnlineStatus(
      isOnline: false,
      lat: 7.828,
      lng: 123.434,
    );

    expect(result.isErr, isTrue);
    result.fold(
      (failure) => expect(
        failure.message,
        'Finish your active ride before going offline.',
      ),
      (_) => fail('Expected the active-ride availability conflict.'),
    );
  });

  test('clears local state even when remote offline call fails', () async {
    final availabilityDataSource = MockAvailabilityRemoteDataSource();
    final sessionService = MockSecureSessionService();
    final telemetryService = MockBackgroundTelemetryService();

    when(() => sessionService.readDriverId())
        .thenAnswer((_) async => 'driver-42');
    when(
      () => availabilityDataSource.updateOnlineStatus(
        driverId: 'driver-42',
        isOnline: false,
      ),
    ).thenThrow(_httpFailure(statusCode: 403));
    when(() => _rideRepository.clearDriverLocation())
        .thenAnswer((_) async => const Ok(null));
    when(() => sessionService.saveDriverOnlineStatus(false))
        .thenAnswer((_) async {});
    when(() => telemetryService.stop()).thenAnswer((_) async {});

    final repository = _buildRepository(
      availabilityDataSource: availabilityDataSource,
      sessionService: sessionService,
      backgroundTelemetryService: telemetryService,
    );

    final result = await repository.updateOnlineStatus(
      isOnline: false,
      lat: 7.828,
      lng: 123.434,
    );

    expect(result.isErr, isTrue);
    verify(() => sessionService.saveDriverOnlineStatus(false)).called(1);
    verify(() => telemetryService.stop()).called(1);
  });

  test(
    'keeps the server error actionable when availability update fails',
    () async {
      final availabilityDataSource = MockAvailabilityRemoteDataSource();
      final sessionService = MockSecureSessionService();

      when(() => sessionService.readDriverId())
          .thenAnswer((_) async => 'driver-42');
      when(
        () => _rideRepository.publishDriverLocation(
          latitude: 7.828,
          longitude: 123.434,
        ),
      ).thenAnswer((_) async => const Ok(null));
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
      when(() => _rideRepository.clearDriverLocation())
          .thenAnswer((_) async => const Ok(null));
      when(() => sessionService.saveDriverOnlineStatus(false))
          .thenAnswer((_) async {});

      final repository = _buildRepository(
        availabilityDataSource: availabilityDataSource,
        sessionService: sessionService,
      );

      final result = await repository.updateOnlineStatus(
        isOnline: true,
        lat: 7.828,
        lng: 123.434,
      );

      expect(result.isErr, isTrue);
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

  group('getPersistedOnlineStatus', () {
    test('returns false when stored online status is false', () async {
      final availabilityDataSource = MockAvailabilityRemoteDataSource();
      final sessionService = MockSecureSessionService();
      when(() => sessionService.readDriverOnlineStatus())
          .thenAnswer((_) async => false);

      final repository = _buildRepository(
        availabilityDataSource: availabilityDataSource,
        sessionService: sessionService,
      );

      final result = await repository.getPersistedOnlineStatus();
      expect(result, const Ok<bool, Failure>(false));
    });

    test('returns false when stored online status is null', () async {
      final availabilityDataSource = MockAvailabilityRemoteDataSource();
      final sessionService = MockSecureSessionService();
      when(() => sessionService.readDriverOnlineStatus())
          .thenAnswer((_) async => null);

      final repository = _buildRepository(
        availabilityDataSource: availabilityDataSource,
        sessionService: sessionService,
      );

      final result = await repository.getPersistedOnlineStatus();
      expect(result, const Ok<bool, Failure>(false));
    });

    test(
      'expires online status when driver has no last active timestamp',
      () async {
        final availabilityDataSource = MockAvailabilityRemoteDataSource();
        final sessionService = MockSecureSessionService();

        when(() => sessionService.readDriverOnlineStatus())
            .thenAnswer((_) async => true);
        when(() => sessionService.readActiveRideId())
            .thenAnswer((_) async => null);
        when(() => sessionService.readDriverLastActive())
            .thenAnswer((_) async => null);
        when(() => sessionService.readDriverId())
            .thenAnswer((_) async => 'driver-42');
        when(() => sessionService.saveDriverOnlineStatus(false))
            .thenAnswer((_) async {});
        when(() => sessionService.clearDriverLastActive())
            .thenAnswer((_) async {});
        when(
          () => availabilityDataSource.updateOnlineStatus(
            driverId: 'driver-42',
            isOnline: false,
          ),
        ).thenAnswer((_) async {});
        when(() => _rideRepository.clearDriverLocationResult())
            .thenAnswer((_) async => const Ok(null));

        final repository = _buildRepository(
          availabilityDataSource: availabilityDataSource,
          sessionService: sessionService,
        );

        final result = await repository.getPersistedOnlineStatus();
        expect(result, const Ok<bool, Failure>(false));
        verify(() => sessionService.saveDriverOnlineStatus(false)).called(1);
        verify(() => sessionService.clearDriverLastActive()).called(1);
        verify(
          () => availabilityDataSource.updateOnlineStatus(
            driverId: 'driver-42',
            isOnline: false,
          ),
        ).called(1);
      },
    );

    test(
      'expires online status when inactivity exceeds max duration',
      () async {
        final availabilityDataSource = MockAvailabilityRemoteDataSource();
        final sessionService = MockSecureSessionService();
        final now = DateTime.utc(2026, 11, 5, 12, 10);
        final lastActive = DateTime.utc(
          2026,
          11,
          5,
          12,
          5,
        ); // 5 mins ago (> 3 mins)

        when(() => sessionService.readDriverOnlineStatus())
            .thenAnswer((_) async => true);
        when(() => sessionService.readActiveRideId())
            .thenAnswer((_) async => null);
        when(() => sessionService.readDriverLastActive())
            .thenAnswer((_) async => lastActive);
        when(() => sessionService.readDriverId())
            .thenAnswer((_) async => 'driver-42');
        when(() => sessionService.saveDriverOnlineStatus(false))
            .thenAnswer((_) async {});
        when(() => sessionService.clearDriverLastActive())
            .thenAnswer((_) async {});
        when(
          () => availabilityDataSource.updateOnlineStatus(
            driverId: 'driver-42',
            isOnline: false,
          ),
        ).thenAnswer((_) async {});
        when(() => _rideRepository.clearDriverLocationResult())
            .thenAnswer((_) async => const Ok(null));

        final repository = _buildRepository(
          availabilityDataSource: availabilityDataSource,
          sessionService: sessionService,
          now: () => now,
          maxInactivityDuration: const Duration(minutes: 3),
        );

        final result = await repository.getPersistedOnlineStatus();
        expect(result, const Ok<bool, Failure>(false));
        verify(() => sessionService.saveDriverOnlineStatus(false)).called(1);
        verify(() => sessionService.clearDriverLastActive()).called(1);
        verify(
          () => availabilityDataSource.updateOnlineStatus(
            driverId: 'driver-42',
            isOnline: false,
          ),
        ).called(1);
      },
    );

    test(
      'preserves online status when inactivity is within max duration',
      () async {
        final availabilityDataSource = MockAvailabilityRemoteDataSource();
        final sessionService = MockSecureSessionService();
        final now = DateTime.utc(2026, 11, 5, 12, 10);
        final lastActive = DateTime.utc(
          2026,
          11,
          5,
          12,
          8,
        ); // 2 mins ago (< 3 mins)

        when(() => sessionService.readDriverOnlineStatus())
            .thenAnswer((_) async => true);
        when(() => sessionService.readActiveRideId())
            .thenAnswer((_) async => null);
        when(() => sessionService.readDriverLastActive())
            .thenAnswer((_) async => lastActive);
        when(() => sessionService.saveDriverLastActive(now))
            .thenAnswer((_) async {});

        final repository = _buildRepository(
          availabilityDataSource: availabilityDataSource,
          sessionService: sessionService,
          now: () => now,
          maxInactivityDuration: const Duration(minutes: 3),
        );

        final result = await repository.getPersistedOnlineStatus();
        expect(result, const Ok<bool, Failure>(true));
        verify(() => sessionService.saveDriverLastActive(now)).called(1);
        verifyNever(() => sessionService.saveDriverOnlineStatus(false));
      },
    );

    test(
      'preserves online status if driver has an active ride even if inactive',
      () async {
        final availabilityDataSource = MockAvailabilityRemoteDataSource();
        final sessionService = MockSecureSessionService();
        final now = DateTime.utc(2026, 11, 5, 12, 10);

        when(() => sessionService.readDriverOnlineStatus())
            .thenAnswer((_) async => true);
        when(() => sessionService.readActiveRideId())
            .thenAnswer((_) async => 'ride-123');
        when(() => sessionService.saveDriverLastActive(now))
            .thenAnswer((_) async {});

        final repository = _buildRepository(
          availabilityDataSource: availabilityDataSource,
          sessionService: sessionService,
          now: () => now,
          maxInactivityDuration: const Duration(minutes: 3),
        );

        final result = await repository.getPersistedOnlineStatus();
        expect(result, const Ok<bool, Failure>(true));
        verify(() => sessionService.saveDriverLastActive(now)).called(1);
        verifyNever(() => sessionService.saveDriverOnlineStatus(false));
      },
    );
  });

  group('recordActivity', () {
    test('updates last active timestamp when driver is online', () async {
      final availabilityDataSource = MockAvailabilityRemoteDataSource();
      final sessionService = MockSecureSessionService();
      final now = DateTime.utc(2026, 11, 5, 12, 10);

      when(() => sessionService.readDriverOnlineStatus())
          .thenAnswer((_) async => true);
      when(() => sessionService.saveDriverLastActive(now))
          .thenAnswer((_) async {});

      final repository = _buildRepository(
        availabilityDataSource: availabilityDataSource,
        sessionService: sessionService,
        now: () => now,
      );

      final result = await repository.recordActivity();
      expect(result, const Ok<void, Failure>(null));
      verify(() => sessionService.saveDriverLastActive(now)).called(1);
    });

    test('does not update timestamp when driver is offline', () async {
      final availabilityDataSource = MockAvailabilityRemoteDataSource();
      final sessionService = MockSecureSessionService();
      final now = DateTime.utc(2026, 11, 5, 12, 10);

      when(() => sessionService.readDriverOnlineStatus())
          .thenAnswer((_) async => false);

      final repository = _buildRepository(
        availabilityDataSource: availabilityDataSource,
        sessionService: sessionService,
        now: () => now,
      );

      final result = await repository.recordActivity();
      expect(result, const Ok<void, Failure>(null));
      verifyNever(() => sessionService.saveDriverLastActive(any()));
    });
  });
}
