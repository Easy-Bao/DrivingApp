import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/features/trip/data/datasources/bidding_remote_data_source.dart';

class MockDio extends Mock implements Dio {}

void main() {
  test('requests profiles only for bounded nearby driver ids', () async {
    final dio = MockDio();
    final dataSource = BiddingRemoteDataSourceImpl(dio);
    when(
      () => dio.get<List<dynamic>>(
        any(),
        queryParameters: any<Map<String, dynamic>>(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response<List<dynamic>>(
        requestOptions: RequestOptions(path: '/api/v1/drivers/online'),
        statusCode: 200,
        data: const [],
      ),
    );

    await dataSource.fetchOnlineDrivers(const ['7', '9']);

    verify(
      () => dio.get<List<dynamic>>(
        '/api/v1/drivers/online',
        queryParameters: <String, dynamic>{'ids': '7,9'},
      ),
    ).called(1);
  });

  test('reads driver telemetry through the ride-scoped endpoint', () async {
    final dio = MockDio();
    final dataSource = BiddingRemoteDataSourceImpl(dio);
    when(() => dio.get<Map<String, dynamic>>(any())).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(
          path: '/api/v1/telemetry/rides/303/driver',
        ),
        statusCode: 200,
        data: const {
          'driver_id': '42',
          'latitude': 7.828,
          'longitude': 123.434,
        },
      ),
    );

    final location = await dataSource.fetchDriverLocation('303');

    verify(
      () => dio.get<Map<String, dynamic>>('/api/v1/telemetry/rides/303/driver'),
    ).called(1);
    expect(location?['driver_id'], '42');
  });

  test(
    'publishes canonical passenger telemetry without identity fields',
    () async {
      final dio = MockDio();
      final dataSource = BiddingRemoteDataSourceImpl(dio);
      Map<String, dynamic>? payload;
      when(
        () => dio.post<Map<String, dynamic>>(
          any(),
          data: any<dynamic>(named: 'data'),
        ),
      ).thenAnswer((invocation) async {
        payload = Map<String, dynamic>.from(
          invocation.namedArguments[#data] as Map,
        );
        return Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(
            path: '/api/v1/telemetry/passenger/303',
          ),
          statusCode: 200,
        );
      });

      final sent = await dataSource.sendPassengerLocation(
        rideId: '303',
        lat: 7.828,
        lng: 123.434,
      );

      expect(sent, isTrue);
      expect(payload, {'latitude': 7.828, 'longitude': 123.434});
    },
  );

  test(
    'loads contact details through the ride counterparty endpoint',
    () async {
      final dio = MockDio();
      final dataSource = BiddingRemoteDataSourceImpl(dio);
      when(() => dio.get<Map<String, dynamic>>(any())).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(
            path: '/api/v1/rides/303/counterparty',
          ),
          statusCode: 200,
          data: const {'role': 'driver', 'phone': '+639000000000'},
        ),
      );

      final counterparty = await dataSource.getRideCounterparty('303');

      verify(
        () => dio.get<Map<String, dynamic>>('/api/v1/rides/303/counterparty'),
      ).called(1);
      expect(counterparty['role'], 'driver');
    },
  );

  test('accepts the created response from driver review submission', () async {
    final dio = MockDio();
    final dataSource = BiddingRemoteDataSourceImpl(dio);
    when(
      () => dio.post<Map<String, dynamic>>(
        any(),
        data: any<dynamic>(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/api/v1/drivers/42/reviews'),
        statusCode: 201,
        data: const {'id': 1},
      ),
    );

    final submitted = await dataSource.submitDriverReview(
      driverId: '42',
      rideId: '303',
      rating: 5,
      comment: 'Safe trip',
    );

    expect(submitted, isTrue);
  });
}
