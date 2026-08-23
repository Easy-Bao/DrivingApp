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
      when(
        () => remoteDataSource.fetchRideHistory(
          'private-id',
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenThrow(
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
      () => remoteDataSource.fetchRideHistory(
        'passenger-1',
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
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
      when(
        () => remoteDataSource.fetchRideHistory(
          'passenger-1',
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer(
        (_) async => const OffsetPage<Map<String, dynamic>>(
          items: [
            <String, dynamic>{
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
          hasMore: false,
          nextOffset: null,
        ),
      );

      final result = await repository.fetchRideHistory('passenger-1');

      result.fold((_) => fail('Expected ride history to load.'), (page) {
        expect(page.items, hasLength(1));
        expect(page.items.single.price, '₱28.17');
        expect(page.items.single.driverName, 'Demo Driver');
        expect(page.items.single.vehicleType, 'Motorcycle');
        expect(page.items.single.vehiclePlate, 'ABC-123');
        expect(page.items.single.date, contains('5:30 PM'));
      });
    },
  );

  test('combines page one with the authoritative weekly summary', () async {
    when(
      () => remoteDataSource.fetchRideHistory(
        'passenger-1',
        limit: 25,
        offset: 0,
      ),
    ).thenAnswer(
      (_) async => const OffsetPage<Map<String, dynamic>>(
        items: [],
        hasMore: false,
        nextOffset: null,
      ),
    );
    when(() => remoteDataSource.fetchActivitySummary('passenger-1')).thenAnswer(
      (_) async => const {
        'this_week_fare_centavos': 21426,
        'this_week_completed_rides': 6,
      },
    );

    final result = await repository.fetchActivityOverview('passenger-1');

    result.fold((_) => fail('Expected activity overview to load.'), (overview) {
      expect(overview.weeklyFareCentavos, 21426);
      expect(overview.weeklyRideCount, 6);
      expect(overview.rides.items, isEmpty);
    });
  });
}
