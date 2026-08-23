import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/features/trip/data/datasources/ride_remote_data_source.dart';

class MockDio extends Mock implements Dio {}

void main() {
  test('reads driver telemetry through the ride-scoped endpoint', () async {
    final dio = MockDio();
    final dataSource = RideRemoteDataSourceImpl(dio);
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
      final dataSource = RideRemoteDataSourceImpl(dio);
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
        latitude: 7.828,
        longitude: 123.434,
      );

      expect(sent, isTrue);
      expect(payload, {'latitude': 7.828, 'longitude': 123.434});
    },
  );

  test(
    'loads contact details through the ride counterparty endpoint',
    () async {
      final dio = MockDio();
      final dataSource = RideRemoteDataSourceImpl(dio);
      when(() => dio.get<Map<String, dynamic>>(any())).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(
            path: '/api/v1/rides/303/counterparty',
          ),
          statusCode: 200,
          data: const {'role': 'driver', 'phone': '+639000000000'},
        ),
      );

      final counterparty = await dataSource.fetchCounterparty('303');

      verify(
        () => dio.get<Map<String, dynamic>>('/api/v1/rides/303/counterparty'),
      ).called(1);
      expect(counterparty['role'], 'driver');
    },
  );
}
