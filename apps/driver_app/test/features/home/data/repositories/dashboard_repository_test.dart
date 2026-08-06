import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/features/home/data/datasources/driver_remote_data_source.dart';
import 'package:driver_app/src/features/home/data/repositories/dashboard_repository.dart';
import 'package:driver_app/src/features/trip/data/datasources/telemetry_remote_data_source.dart';
import 'package:driver_app/src/features/trip/data/datasources/trip_remote_data_source.dart';
import 'package:shared_core/shared_core.dart';

class MockDriverRemoteDataSource extends Mock
    implements DriverRemoteDataSource {}

class MockTelemetryRemoteDataSource extends Mock
    implements TelemetryRemoteDataSource {}

class MockTripRemoteDataSource extends Mock implements TripRemoteDataSource {}

class MockSecureSessionService extends Mock implements SecureSessionService {}

void main() {
  test('publishes the initial driver location when going online', () async {
    final driverDataSource = MockDriverRemoteDataSource();
    final telemetryDataSource = MockTelemetryRemoteDataSource();
    final tripDataSource = MockTripRemoteDataSource();
    final sessionService = MockSecureSessionService();

    when(
      () => sessionService.readDriverId(),
    ).thenAnswer((_) async => 'driver-42');
    when(
      () => driverDataSource.updateOnlineStatus(
        driverId: 'driver-42',
        isOnline: true,
        lat: 7.828,
        lng: 123.434,
      ),
    ).thenAnswer((_) async {});
    when(
      () => telemetryDataSource.sendLocationUpdate(
        driverId: 'driver-42',
        lat: 7.828,
        lng: 123.434,
      ),
    ).thenAnswer((_) async => true);
    when(
      () => sessionService.saveDriverOnlineStatus(true),
    ).thenAnswer((_) async {});

    final repository = DashboardRepository(
      remoteDataSource: tripDataSource,
      driverRemoteDataSource: driverDataSource,
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
      () => telemetryDataSource.sendLocationUpdate(
        driverId: 'driver-42',
        lat: 7.828,
        lng: 123.434,
      ),
    ).called(1);
  });

  test(
    'does not mark the driver online when initial location publishing fails',
    () async {
      final driverDataSource = MockDriverRemoteDataSource();
      final telemetryDataSource = MockTelemetryRemoteDataSource();
      final tripDataSource = MockTripRemoteDataSource();
      final sessionService = MockSecureSessionService();

      when(
        () => sessionService.readDriverId(),
      ).thenAnswer((_) async => 'driver-42');
      when(
        () => telemetryDataSource.sendLocationUpdate(
          driverId: 'driver-42',
          lat: 7.828,
          lng: 123.434,
        ),
      ).thenAnswer((_) async => false);

      final repository = DashboardRepository(
        remoteDataSource: tripDataSource,
        driverRemoteDataSource: driverDataSource,
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
      verifyNever(
        () => driverDataSource.updateOnlineStatus(
          driverId: any(named: 'driverId'),
          isOnline: any(named: 'isOnline'),
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
        ),
      );
    },
  );

  test('removes the driver location when going offline', () async {
    final driverDataSource = MockDriverRemoteDataSource();
    final telemetryDataSource = MockTelemetryRemoteDataSource();
    final tripDataSource = MockTripRemoteDataSource();
    final sessionService = MockSecureSessionService();

    when(
      () => sessionService.readDriverId(),
    ).thenAnswer((_) async => 'driver-42');
    when(
      () => driverDataSource.updateOnlineStatus(
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
      remoteDataSource: tripDataSource,
      driverRemoteDataSource: driverDataSource,
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
}
