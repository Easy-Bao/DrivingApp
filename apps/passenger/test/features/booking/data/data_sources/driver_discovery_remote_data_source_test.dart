import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/features/booking/data/data_sources/driver_discovery_remote_data_source.dart';

class MockDio extends Mock implements Dio {}

void main() {
  test(
    'normalizes online driver objects at the data-source boundary',
    () async {
      final dio = MockDio();
      final dataSource = DriverDiscoveryRemoteDataSourceImpl(dio);
      when(
        () => dio.get<List<dynamic>>(
          any(),
          queryParameters: any<Map<String, dynamic>>(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<List<dynamic>>(
          requestOptions: RequestOptions(path: '/api/v1/drivers/online'),
          statusCode: 200,
          data: <dynamic>[
            <String, dynamic>{'id': 7},
            'malformed driver',
            <String, dynamic>{'id': 9},
          ],
        ),
      );

      final result = await dataSource.fetchOnlineDrivers(const ['7', '9']);

      expect(result, <Map<String, dynamic>>[
        <String, dynamic>{'id': 7},
        <String, dynamic>{'id': 9},
      ]);

      verify(
        () => dio.get<List<dynamic>>(
          '/api/v1/drivers/online',
          queryParameters: <String, dynamic>{'ids': '7,9'},
        ),
      ).called(1);
    },
  );

  test('normalizes nearby driver objects from the response envelope', () async {
    final dio = MockDio();
    final dataSource = DriverDiscoveryRemoteDataSourceImpl(dio);
    when(
      () => dio.get<Map<String, dynamic>>(
        '/api/v1/telemetry/location/nearby',
        queryParameters: any<Map<String, dynamic>>(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(
          path: '/api/v1/telemetry/location/nearby',
        ),
        statusCode: 200,
        data: <String, dynamic>{
          'drivers': <dynamic>[
            <String, dynamic>{'driver_id': 7},
            'malformed driver',
          ],
        },
      ),
    );

    final result = await dataSource.fetchNearbyDrivers(
      latitude: 7.828,
      longitude: 123.434,
    );

    expect(result, <Map<String, dynamic>>[
      <String, dynamic>{'driver_id': 7},
    ]);
  });
}
