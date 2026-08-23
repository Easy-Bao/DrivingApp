import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:driver_app/src/core/services/background_telemetry_service.dart';
import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/features/home/data/datasources/driver_availability_remote_data_source.dart';
import 'package:driver_app/src/features/home/data/repositories/dashboard_repository.dart';
import 'package:driver_app/src/features/home/domain/entities/driver_dashboard_stats.dart';
import 'package:driver_app/src/features/trip/data/datasources/telemetry_remote_data_source.dart';
import 'package:driver_app/src/features/activity/data/datasources/driver_activity_remote_data_source.dart';
import 'package:shared_core/shared_core.dart';

class MockDriverAvailabilityRemoteDataSource extends Mock
    implements DriverAvailabilityRemoteDataSource {}

class MockTelemetryRemoteDataSource extends Mock
    implements TelemetryRemoteDataSource {}

class MockDriverActivityRemoteDataSource extends Mock
    implements DriverActivityRemoteDataSource {}

class MockSecureSessionService extends Mock implements SecureSessionService {}

class MockBackgroundTelemetryService extends Mock
    implements BackgroundTelemetryService {}

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
  test(
    'maps completed trip statistics from the server contract once',
    () async {
      final availabilityDataSource = MockDriverAvailabilityRemoteDataSource();
      final telemetryDataSource = MockTelemetryRemoteDataSource();
      final activityDataSource = MockDriverActivityRemoteDataSource();
      final sessionService = MockSecureSessionService();

      when(
        () => sessionService.readDriverId(),
      ).thenAnswer((_) async => 'driver-42');
      when(() => activityDataSource.fetchStats('driver-42')).thenAnswer(
        (_) async => <String, dynamic>{
          'today_earnings_centavos': 2817,
          'today_completed_trips': 1,
        },
      );

      final repository = DashboardRepository(
        activityDataSource: activityDataSource,
        availabilityDataSource: availabilityDataSource,
        telemetryRemoteDataSource: telemetryDataSource,
        sessionService: sessionService,
      );

      final result = await repository.getDashboardStats();

      expect(
        result,
        const Right<Failure, DriverDashboardStats>(
          DriverDashboardStats(earnings: 28.17, completedTrips: 1),
        ),
      );
      verify(() => activityDataSource.fetchStats('driver-42')).called(1);
    },
  );

  test('publishes the initial driver location when going online', () async {
    final availabilityDataSource = MockDriverAvailabilityRemoteDataSource();
    final telemetryDataSource = MockTelemetryRemoteDataSource();
    final activityDataSource = MockDriverActivityRemoteDataSource();
    final sessionService = MockSecureSessionService();

    when(
      () => sessionService.readDriverId(),
    ).thenAnswer((_) async => 'driver-42');
    when(
      () => availabilityDataSource.updateOnlineStatus(
        driverId: 'driver-42',
        isOnline: true,
        lat: 7.828,
        lng: 123.434,
      ),
    ).thenAnswer((_) async {});
    when(
      () => telemetryDataSource.sendLocationUpdate(lat: 7.828, lng: 123.434),
    ).thenAnswer((_) async => true);
    when(
      () => sessionService.saveDriverOnlineStatus(true),
    ).thenAnswer((_) async {});

    final repository = DashboardRepository(
      activityDataSource: activityDataSource,
      availabilityDataSource: availabilityDataSource,
      telemetryRemoteDataSource: telemetryDataSource,
      sessionService: sessionService,
    );

    final result = await repository.updateOnlineStatus(
      isOnline: true,
      lat: 7.828,
      lng: 123.434,
    );

    expect(result, const Right<Failure, void>(null));
    verify(
      () => telemetryDataSource.sendLocationUpdate(lat: 7.828, lng: 123.434),
    ).called(1);
  });

  test(
    'does not mark the driver online when initial location publishing fails',
    () async {
      final availabilityDataSource = MockDriverAvailabilityRemoteDataSource();
      final telemetryDataSource = MockTelemetryRemoteDataSource();
      final activityDataSource = MockDriverActivityRemoteDataSource();
      final sessionService = MockSecureSessionService();

      when(
        () => sessionService.readDriverId(),
      ).thenAnswer((_) async => 'driver-42');
      when(
        () => telemetryDataSource.sendLocationUpdate(lat: 7.828, lng: 123.434),
      ).thenAnswer((_) async => false);
      when(
        () => availabilityDataSource.updateOnlineStatus(
          driverId: 'driver-42',
          isOnline: false,
          lat: 7.828,
          lng: 123.434,
        ),
      ).thenAnswer((_) async {});
      when(
        () => telemetryDataSource.removeLocation(),
      ).thenAnswer((_) async => true);
      when(
        () => sessionService.saveDriverOnlineStatus(false),
      ).thenAnswer((_) async {});

      final repository = DashboardRepository(
        activityDataSource: activityDataSource,
        availabilityDataSource: availabilityDataSource,
        telemetryRemoteDataSource: telemetryDataSource,
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
          lat: 7.828,
          lng: 123.434,
        ),
      ).called(1);
      verifyNever(
        () => availabilityDataSource.updateOnlineStatus(
          driverId: 'driver-42',
          isOnline: true,
          lat: 7.828,
          lng: 123.434,
        ),
      );
      verify(() => telemetryDataSource.removeLocation()).called(1);
      verify(() => sessionService.saveDriverOnlineStatus(false)).called(1);
    },
  );

  test(
    'keeps the driver online when optional background telemetry cannot start',
    () async {
      final availabilityDataSource = MockDriverAvailabilityRemoteDataSource();
      final telemetryDataSource = MockTelemetryRemoteDataSource();
      final activityDataSource = MockDriverActivityRemoteDataSource();
      final sessionService = MockSecureSessionService();
      final backgroundService = MockBackgroundTelemetryService();

      when(
        () => sessionService.readDriverId(),
      ).thenAnswer((_) async => 'driver-42');
      when(
        () => telemetryDataSource.sendLocationUpdate(lat: 7.828, lng: 123.434),
      ).thenAnswer((_) async => true);
      when(
        () => availabilityDataSource.updateOnlineStatus(
          driverId: 'driver-42',
          isOnline: true,
          lat: 7.828,
          lng: 123.434,
        ),
      ).thenAnswer((_) async {});
      when(
        () => sessionService.saveDriverOnlineStatus(true),
      ).thenAnswer((_) async {});
      when(
        () => backgroundService.start(),
      ).thenThrow(StateError('not configured'));

      final repository = DashboardRepository(
        activityDataSource: activityDataSource,
        availabilityDataSource: availabilityDataSource,
        telemetryRemoteDataSource: telemetryDataSource,
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
          lat: 7.828,
          lng: 123.434,
        ),
      );
      verifyNever(() => telemetryDataSource.removeLocation());
      verify(() => sessionService.saveDriverOnlineStatus(true)).called(1);
    },
  );

  test('removes the driver location when going offline', () async {
    final availabilityDataSource = MockDriverAvailabilityRemoteDataSource();
    final telemetryDataSource = MockTelemetryRemoteDataSource();
    final activityDataSource = MockDriverActivityRemoteDataSource();
    final sessionService = MockSecureSessionService();

    when(
      () => sessionService.readDriverId(),
    ).thenAnswer((_) async => 'driver-42');
    when(
      () => availabilityDataSource.updateOnlineStatus(
        driverId: 'driver-42',
        isOnline: false,
        lat: 7.828,
        lng: 123.434,
      ),
    ).thenAnswer((_) async {});
    when(
      () => telemetryDataSource.removeLocation(),
    ).thenAnswer((_) async => true);
    when(
      () => sessionService.saveDriverOnlineStatus(false),
    ).thenAnswer((_) async {});

    final repository = DashboardRepository(
      activityDataSource: activityDataSource,
      availabilityDataSource: availabilityDataSource,
      telemetryRemoteDataSource: telemetryDataSource,
      sessionService: sessionService,
    );

    final result = await repository.updateOnlineStatus(
      isOnline: false,
      lat: 7.828,
      lng: 123.434,
    );

    expect(result, const Right<Failure, void>(null));
    verify(() => telemetryDataSource.removeLocation()).called(1);
  });

  test(
    'keeps the server error actionable when availability update fails',
    () async {
      final availabilityDataSource = MockDriverAvailabilityRemoteDataSource();
      final telemetryDataSource = MockTelemetryRemoteDataSource();
      final activityDataSource = MockDriverActivityRemoteDataSource();
      final sessionService = MockSecureSessionService();

      when(
        () => sessionService.readDriverId(),
      ).thenAnswer((_) async => 'driver-42');
      when(
        () => telemetryDataSource.sendLocationUpdate(lat: 7.828, lng: 123.434),
      ).thenAnswer((_) async => true);
      when(
        () => availabilityDataSource.updateOnlineStatus(
          driverId: 'driver-42',
          isOnline: true,
          lat: 7.828,
          lng: 123.434,
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
          lat: 7.828,
          lng: 123.434,
        ),
      ).thenAnswer((_) async {});
      when(
        () => telemetryDataSource.removeLocation(),
      ).thenAnswer((_) async => true);
      when(
        () => sessionService.saveDriverOnlineStatus(false),
      ).thenAnswer((_) async {});

      final repository = DashboardRepository(
        activityDataSource: activityDataSource,
        availabilityDataSource: availabilityDataSource,
        telemetryRemoteDataSource: telemetryDataSource,
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
      verify(() => telemetryDataSource.removeLocation()).called(1);
      verify(() => sessionService.saveDriverOnlineStatus(false)).called(1);
    },
  );
}
