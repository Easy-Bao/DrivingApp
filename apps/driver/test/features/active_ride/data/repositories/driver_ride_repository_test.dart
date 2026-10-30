import 'dart:async';

import 'package:driver/src/features/active_ride/active_ride.dart';
import 'package:driver/src/features/active_ride/data/data_sources/ride_counterparty_remote_data_source.dart';
import 'package:driver/src/features/active_ride/data/data_sources/ride_remote_data_source.dart';
import 'package:driver/src/features/active_ride/data/data_sources/telemetry_remote_data_source.dart';
import 'package:driver/src/features/active_ride/data/repositories/driver_ride_repository_impl.dart';
import 'package:driver/src/features/active_ride/domain/repositories/driver_ride_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:foundation/foundation.dart';

class MockRideRemoteDataSource extends Mock implements RideRemoteDataSource {}

class MockRideCounterpartyRemoteDataSource extends Mock
    implements RideCounterpartyRemoteDataSource {}

class MockTelemetryRemoteDataSource extends Mock
    implements TelemetryRemoteDataSource {}

void main() {
  late MockRideRemoteDataSource rideDataSource;
  late MockRideCounterpartyRemoteDataSource counterpartyDataSource;
  late MockTelemetryRemoteDataSource telemetryDataSource;
  late RideRepositoryImpl repository;

  setUp(() {
    rideDataSource = MockRideRemoteDataSource();
    counterpartyDataSource = MockRideCounterpartyRemoteDataSource();
    telemetryDataSource = MockTelemetryRemoteDataSource();
    repository = RideRepositoryImpl(
      rideDataSource: rideDataSource,
      counterpartyDataSource: counterpartyDataSource,
      telemetryDataSource: telemetryDataSource,
    );
  });

  test('normalizes ride identifiers, coordinates, and fare amount', () async {
    when(() => rideDataSource.getRideStatus('ride-7')).thenAnswer(
      (_) async => <String, dynamic>{
        'id': 7,
        'status': 'IN_TRANSIT',
        'pickup_name': 'Mountain View',
        'dropoff_name': 'Vista Slope',
        'passenger_id': 12,
        'dropoff_latitude': '7.85',
        'dropoff_longitude': 123.45,
        'fare_amount': '2764',
      },
    );

    final result = await repository.fetchRide('ride-7');

    expect(
      result,
      const Ok<RideSnapshot, Failure>(
        RideSnapshot(
          id: '7',
          status: 'in_transit',
          pickupName: 'Mountain View',
          dropoffName: 'Vista Slope',
          passengerId: '12',
          dropoffLatitude: 7.85,
          dropoffLongitude: 123.45,
          fareAmount: 2764,
        ),
      ),
    );
  });

  test('preserves a missing ride as a terminal lookup failure', () async {
    when(() => rideDataSource.getRideStatus('ride-7'))
        .thenThrow(_responseException(404));

    final result = await repository.fetchRide('ride-7');

    expect(
      result.fold((failure) => failure, (_) => null),
      isA<RideNotFoundFailure>(),
    );
  });

  test(
    'requires the server arrival response to include its wait timer',
    () async {
      final observedAt = DateTime.utc(2026, 10, 11, 10);
      when(
        () => telemetryDataSource.sendLocationUpdate(
          lat: 7.82,
          lng: 123.43,
          observedAt: observedAt,
        ),
      ).thenAnswer((_) async => true);
      when(
        () => rideDataSource.markArrived(
          rideId: 'ride-7',
          latitude: 7.82,
          longitude: 123.43,
        ),
      ).thenAnswer(
        (_) async => <String, dynamic>{
          'id': 'ride-7',
          'status': 'arrived',
          'pickup_name': 'Mountain View',
          'dropoff_name': 'Vista Slope',
          'arrived_at': '2026-10-04T10:00:00Z',
          'waiting_until': '2026-10-04T10:05:00Z',
        },
      );

      final result = await repository.markArrived(
        rideId: 'ride-7',
        latitude: 7.82,
        longitude: 123.43,
        observedAt: observedAt,
      );

      expect(result, isA<Ok<RideSnapshot, Failure>>());
      expect(
        result.fold((_) => null, (ride) => ride.waitingUntil),
        DateTime.parse('2026-10-04T10:05:00Z'),
      );
    },
  );

  test('waits for fresh telemetry before confirming arrival', () async {
    const latitude = 7.82;
    const longitude = 123.43;
    final observedAt = DateTime.utc(2026, 10, 11, 10);
    final telemetryStarted = Completer<void>();
    final completeTelemetry = Completer<bool>();
    var transitionCalled = false;
    when(
      () => telemetryDataSource.sendLocationUpdate(
        lat: latitude,
        lng: longitude,
        observedAt: observedAt,
      ),
    ).thenAnswer((_) {
      telemetryStarted.complete();
      return completeTelemetry.future;
    });
    when(
      () => rideDataSource.markArrived(
        rideId: 'ride-7',
        latitude: latitude,
        longitude: longitude,
      ),
    ).thenAnswer((_) async {
      transitionCalled = true;
      return <String, dynamic>{
        'id': 'ride-7',
        'status': 'arrived',
        'arrived_at': '2026-10-11T10:00:00Z',
        'waiting_until': '2026-10-11T10:05:00Z',
      };
    });

    final result = repository.markArrived(
      rideId: 'ride-7',
      latitude: latitude,
      longitude: longitude,
      observedAt: observedAt,
    );
    await telemetryStarted.future;

    expect(transitionCalled, isFalse);
    completeTelemetry.complete(true);
    await result;

    expect(transitionCalled, isTrue);
  });

  test('does not confirm arrival when fresh telemetry is rejected', () async {
    final observedAt = DateTime.utc(2026, 10, 11, 10);
    when(
      () => telemetryDataSource.sendLocationUpdate(
        lat: 7.82,
        lng: 123.43,
        observedAt: observedAt,
      ),
    ).thenAnswer((_) async => false);

    final result = await repository.markArrived(
      rideId: 'ride-7',
      latitude: 7.82,
      longitude: 123.43,
      observedAt: observedAt,
    );

    expect(
      result.fold((failure) => failure.message, (_) => ''),
      'Your live location could not be updated. Keep location sharing on and try again.',
    );
    verifyNever(
      () => rideDataSource.markArrived(
        rideId: 'ride-7',
        latitude: 7.82,
        longitude: 123.43,
      ),
    );
  });

  test('does not confirm arrival when fresh telemetry fails to post', () async {
    final observedAt = DateTime.utc(2026, 10, 11, 10);
    when(
      () => telemetryDataSource.sendLocationUpdate(
        lat: 7.82,
        lng: 123.43,
        observedAt: observedAt,
      ),
    ).thenThrow(_responseException(500));

    final result = await repository.markArrived(
      rideId: 'ride-7',
      latitude: 7.82,
      longitude: 123.43,
      observedAt: observedAt,
    );

    expect(
      result.fold((failure) => failure.message, (_) => ''),
      'Unable to share your location right now.',
    );
    verifyNever(
      () => rideDataSource.markArrived(
        rideId: 'ride-7',
        latitude: 7.82,
        longitude: 123.43,
      ),
    );
  });

  test(
    'explains when the driver is outside the pickup arrival radius',
    () async {
      final observedAt = DateTime.utc(2026, 10, 11, 10);
      when(
        () => telemetryDataSource.sendLocationUpdate(
          lat: 7.82,
          lng: 123.43,
          observedAt: observedAt,
        ),
      ).thenAnswer((_) async => true);
      when(
        () => rideDataSource.markArrived(
          rideId: 'ride-7',
          latitude: 7.82,
          longitude: 123.43,
        ),
      ).thenThrow(_responseException(422));

      final result = await repository.markArrived(
        rideId: 'ride-7',
        latitude: 7.82,
        longitude: 123.43,
        observedAt: observedAt,
      );

      expect(
        result.fold((failure) => failure.message, (_) => ''),
        "You must be at the passenger's pickup point to confirm arrival.",
      );
    },
  );

  test('explains when location telemetry is stale during arrival', () async {
    final observedAt = DateTime.utc(2026, 10, 11, 10);
    when(
      () => telemetryDataSource.sendLocationUpdate(
        lat: 7.82,
        lng: 123.43,
        observedAt: observedAt,
      ),
    ).thenAnswer((_) async => true);
    when(
      () => rideDataSource.markArrived(
        rideId: 'ride-7',
        latitude: 7.82,
        longitude: 123.43,
      ),
    ).thenThrow(_responseException(503));

    final result = await repository.markArrived(
      rideId: 'ride-7',
      latitude: 7.82,
      longitude: 123.43,
      observedAt: observedAt,
    );

    expect(
      result.fold((failure) => failure.message, (_) => ''),
      'Your live location is unavailable or out of date. Keep location sharing on and try again.',
    );
  });

  test('explains when the driver is outside the pickup start radius', () async {
    final observedAt = DateTime.utc(2026, 10, 11, 10);
    when(
      () => telemetryDataSource.sendLocationUpdate(
        lat: 7.82,
        lng: 123.43,
        observedAt: observedAt,
      ),
    ).thenAnswer((_) async => true);
    when(
      () => rideDataSource.startRide(
        rideId: 'ride-7',
        latitude: 7.82,
        longitude: 123.43,
      ),
    ).thenThrow(_responseException(422));

    final result = await repository.startRide(
      rideId: 'ride-7',
      latitude: 7.82,
      longitude: 123.43,
      observedAt: observedAt,
    );

    expect(
      result.fold((failure) => failure.message, (_) => ''),
      "You must be at the passenger's pickup point to start the trip.",
    );
  });

  test('explains when location telemetry is stale during trip start', () async {
    final observedAt = DateTime.utc(2026, 10, 11, 10);
    when(
      () => telemetryDataSource.sendLocationUpdate(
        lat: 7.82,
        lng: 123.43,
        observedAt: observedAt,
      ),
    ).thenAnswer((_) async => true);
    when(
      () => rideDataSource.startRide(
        rideId: 'ride-7',
        latitude: 7.82,
        longitude: 123.43,
      ),
    ).thenThrow(_responseException(503));

    final result = await repository.startRide(
      rideId: 'ride-7',
      latitude: 7.82,
      longitude: 123.43,
      observedAt: observedAt,
    );

    expect(
      result.fold((failure) => failure.message, (_) => ''),
      'Your live location is unavailable or out of date. Keep location sharing on and try again.',
    );
  });

  test('waits for fresh telemetry before starting the trip', () async {
    const latitude = 7.82;
    const longitude = 123.43;
    final observedAt = DateTime.utc(2026, 10, 11, 10);
    final telemetryStarted = Completer<void>();
    final completeTelemetry = Completer<bool>();
    var transitionCalled = false;
    when(
      () => telemetryDataSource.sendLocationUpdate(
        lat: latitude,
        lng: longitude,
        observedAt: observedAt,
      ),
    ).thenAnswer((_) {
      telemetryStarted.complete();
      return completeTelemetry.future;
    });
    when(
      () => rideDataSource.startRide(
        rideId: 'ride-7',
        latitude: latitude,
        longitude: longitude,
      ),
    ).thenAnswer((_) async {
      transitionCalled = true;
      return <String, dynamic>{'id': 'ride-7', 'status': 'in_transit'};
    });

    final result = repository.startRide(
      rideId: 'ride-7',
      latitude: latitude,
      longitude: longitude,
      observedAt: observedAt,
    );
    await telemetryStarted.future;

    expect(transitionCalled, isFalse);
    completeTelemetry.complete(true);
    await result;

    expect(transitionCalled, isTrue);
  });

  test('does not start the trip when fresh telemetry is rejected', () async {
    final observedAt = DateTime.utc(2026, 10, 11, 10);
    when(
      () => telemetryDataSource.sendLocationUpdate(
        lat: 7.82,
        lng: 123.43,
        observedAt: observedAt,
      ),
    ).thenAnswer((_) async => false);

    final result = await repository.startRide(
      rideId: 'ride-7',
      latitude: 7.82,
      longitude: 123.43,
      observedAt: observedAt,
    );

    expect(
      result.fold((failure) => failure.message, (_) => ''),
      'Your live location could not be updated. Keep location sharing on and try again.',
    );
    verifyNever(
      () => rideDataSource.startRide(
        rideId: 'ride-7',
        latitude: 7.82,
        longitude: 123.43,
      ),
    );
  });

  test('uses dedicated server commands for start and completion', () async {
    final observedAt = DateTime.utc(2026, 10, 11, 10);
    when(
      () => rideDataSource.startRide(
        rideId: 'ride-7',
        latitude: 7.82,
        longitude: 123.43,
      ),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'id': 'ride-7',
        'status': 'in_transit',
        'pickup_name': 'Mountain View',
        'dropoff_name': 'Vista Slope',
      },
    );
    when(
      () => telemetryDataSource.sendLocationUpdate(
        lat: 7.82,
        lng: 123.43,
        observedAt: observedAt,
      ),
    ).thenAnswer((_) async => true);
    when(
      () => rideDataSource.completeRide(
        rideId: 'ride-7',
        latitude: 7.85,
        longitude: 123.45,
      ),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'id': 'ride-7',
        'status': 'completed',
        'pickup_name': 'Mountain View',
        'dropoff_name': 'Vista Slope',
        'fare_amount': 2764,
      },
    );
    when(() => telemetryDataSource.sendLocationUpdate(lat: 7.85, lng: 123.45))
        .thenAnswer((_) async => true);

    final started = await repository.startRide(
      rideId: 'ride-7',
      latitude: 7.82,
      longitude: 123.43,
      observedAt: observedAt,
    );
    final completed = await repository.completeRide(
      rideId: 'ride-7',
      latitude: 7.85,
      longitude: 123.45,
    );

    expect(started.fold((_) => '', (ride) => ride.status), 'in_transit');
    expect(completed.fold((_) => 0, (ride) => ride.fareAmount), 2764);
  });

  test('accepts a server-confirmed safety report', () async {
    when(
      () => rideDataSource.createSafetyReport(
        rideId: 'ride-7',
        category: 'non_payment',
        description: 'Passenger did not pay the agreed cash fare.',
      ),
    ).thenAnswer(
      (_) async => <String, dynamic>{'id': 13, 'status': 'submitted'},
    );

    final result = await repository.createSafetyReport(
      rideId: 'ride-7',
      category: 'non_payment',
      description: 'Passenger did not pay the agreed cash fare.',
    );

    expect(result, isA<Ok<void, Failure>>());
    verify(
      () => rideDataSource.createSafetyReport(
        rideId: 'ride-7',
        category: 'non_payment',
        description: 'Passenger did not pay the agreed cash fare.',
      ),
    ).called(1);
  });

  test('requires the server to confirm a cancelled ride', () async {
    when(
      () => rideDataSource.cancelRide(
        rideId: 'ride-7',
        reason: 'vehicle_problem',
        details: '',
      ),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'id': 'ride-7',
        'status': 'cancelled',
        'pickup_name': 'Mountain View',
        'dropoff_name': 'Vista Slope',
        'cancellation_reason': 'vehicle_problem',
        'cancellation_responsibility': 'driver_fault',
      },
    );

    final result = await repository.cancelRide(
      rideId: 'ride-7',
      reason: 'vehicle_problem',
    );

    expect(result.fold((_) => '', (ride) => ride.status), 'cancelled');
    verify(
      () => rideDataSource.cancelRide(
        rideId: 'ride-7',
        reason: 'vehicle_problem',
        details: '',
      ),
    ).called(1);
  });

  test('requires a safety-attributed emergency-stop response', () async {
    when(
      () => rideDataSource.emergencyStop(
        rideId: 'ride-7',
        reason: 'accident',
        details: 'Minor collision.',
      ),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'id': 'ride-7',
        'status': 'cancelled',
        'cancellation_reason': 'accident',
        'cancellation_responsibility': 'safety_related',
      },
    );

    final result = await repository.emergencyStop(
      rideId: 'ride-7',
      reason: 'accident',
      details: 'Minor collision.',
    );

    expect(result.fold((_) => '', (ride) => ride.status), 'cancelled');
    verify(
      () => rideDataSource.emergencyStop(
        rideId: 'ride-7',
        reason: 'accident',
        details: 'Minor collision.',
      ),
    ).called(1);
  });

  test(
    'adapts passenger reads and location cleanup into strict results',
    () async {
      when(() => counterpartyDataSource.fetch('ride-7')).thenAnswer(
        (_) async => {
          'user_id': 'passenger-42',
          'name': 'Passenger',
          'phone': '+639171234567',
          'contact_allowed': true,
        },
      );
      when(() => telemetryDataSource.fetchPassengerLocation('ride-7'))
          .thenAnswer((_) async => {'lat': '7.828', 'lng': '123.434'});
      when(() => telemetryDataSource.removeLocation())
          .thenAnswer((_) async => true);

      final counterpartyResult = await repository.fetchCounterpartyResult(
        'ride-7',
      );
      final locationResult = await repository.fetchPassengerLocationResult(
        'ride-7',
      );
      final cleanupResult = await repository.clearDriverLocationResult();

      expect(counterpartyResult, isA<Ok<RideCounterparty, DomainFailure>>());
      expect(
        locationResult,
        isA<Ok<(double latitude, double longitude)?, DomainFailure>>(),
      );
      expect(cleanupResult, isA<Ok<void, DomainFailure>>());
      expect(
        counterpartyResult.fold((_) => '', (value) => value.userId),
        'passenger-42',
      );
      expect(
        locationResult.fold<(double, double)?>((_) => null, (value) => value),
        (7.828, 123.434),
      );
    },
  );

  test(
    'returns user-facing message when sharing driver location fails',
    () async {
      when(
        () => telemetryDataSource.sendLocationUpdate(
          lat: 7.82,
          lng: 123.43,
          heading: null,
          speed: null,
        ),
      ).thenThrow(_responseException(500));

      final result = await repository.publishDriverLocationResult(
        latitude: 7.82,
        longitude: 123.43,
      );

      expect(
        result.fold((failure) => failure.message, (_) => ''),
        'Unable to share your location right now.',
      );
    },
  );

  test(
    'returns user-facing message when removing driver location fails',
    () async {
      when(() => telemetryDataSource.removeLocation())
          .thenThrow(_responseException(500));

      final result = await repository.clearDriverLocationResult();

      expect(
        result.fold((failure) => failure.message, (_) => ''),
        'Unable to remove your location right now.',
      );
    },
  );
}

DioException _responseException(int statusCode) {
  final requestOptions = RequestOptions(path: '/api/v1/rides/ride-7');
  return DioException(
    requestOptions: requestOptions,
    response: Response(requestOptions: requestOptions, statusCode: statusCode),
  );
}
