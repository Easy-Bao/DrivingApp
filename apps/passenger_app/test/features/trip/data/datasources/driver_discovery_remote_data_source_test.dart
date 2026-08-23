import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/features/trip/data/datasources/driver_discovery_remote_data_source.dart';

class MockDio extends Mock implements Dio {}

void main() {
  test('requests profiles only for bounded nearby driver ids', () async {
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
}
