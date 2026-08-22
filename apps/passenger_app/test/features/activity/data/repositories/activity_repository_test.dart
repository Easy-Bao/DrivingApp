import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/features/activity/data/repositories/activity_repository.dart';
import 'package:passenger_app/src/features/trip/data/datasources/passenger_remote_data_source.dart';
import 'package:shared_core/shared_core.dart';

class MockPassengerRemoteDataSource extends Mock
    implements PassengerRemoteDataSource {}

void main() {
  late MockPassengerRemoteDataSource remoteDataSource;
  late ActivityRepository repository;

  setUp(() {
    remoteDataSource = MockPassengerRemoteDataSource();
    repository = ActivityRepository(
      passengerRemoteDataSource: remoteDataSource,
    );
  });

  test(
    'maps unauthorized responses to a safe authentication failure',
    () async {
      final request = RequestOptions(
        path: '/api/v1/passengers/private-id/rides',
      );
      when(() => remoteDataSource.fetchRideHistory('private-id')).thenThrow(
        DioException(
          requestOptions: request,
          response: Response<Object?>(requestOptions: request, statusCode: 401),
          type: DioExceptionType.badResponse,
        ),
      );

      final result = await repository.fetchRideHistory('private-id');

      result.fold((failure) {
        expect(failure, isA<AuthFailure>());
        expect(failure.message, contains('Sign in again'));
        expect(failure.message, isNot(contains('DioException')));
        expect(failure.message, isNot(contains('401')));
        expect(failure.message, isNot(contains('private-id')));
      }, (_) => fail('Expected an authentication failure.'));
    },
  );

  test('does not expose unexpected exception diagnostics', () async {
    when(
      () => remoteDataSource.fetchRideHistory('passenger-1'),
    ).thenThrow(StateError('database-password-leak'));

    final result = await repository.fetchRideHistory('passenger-1');

    result.fold((failure) {
      expect(failure, isA<ServerFailure>());
      expect(
        failure.message,
        'Activity is temporarily unavailable. Please try again.',
      );
      expect(failure.message, isNot(contains('database-password-leak')));
    }, (_) => fail('Expected a server failure.'));
  });

  test(
    'maps centavo fares and alternate driver fields from ride history',
    () async {
      when(() => remoteDataSource.fetchRideHistory('passenger-1')).thenAnswer(
        (_) async => [
          {
            'id': 7,
            'pickup_name': 'Pickup, City',
            'dropoff_name': 'Destination, City',
            'created_at': '2026-08-18T08:00:00Z',
            'completed_at': '2026-08-18T09:30:00Z',
            'fare_centavos': 2817,
            'status': 'completed',
            'driver_id': 2,
            'driverName': 'Demo Driver',
            'vehicleType': 'Motorcycle',
            'plateNumber': 'ABC-123',
          },
        ],
      );

      final result = await repository.fetchRideHistory('passenger-1');

      result.fold((_) => fail('Expected ride history to load.'), (rides) {
        expect(rides, hasLength(1));
        expect(rides.single.price, '₱28.17');
        expect(rides.single.driverName, 'Demo Driver');
        expect(rides.single.vehicleType, 'Motorcycle');
        expect(rides.single.vehiclePlate, 'ABC-123');
        expect(rides.single.date, contains('5:30 PM'));
      });
    },
  );
}
