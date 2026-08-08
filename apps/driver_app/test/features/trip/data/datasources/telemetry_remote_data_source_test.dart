import 'package:dio/dio.dart';
import 'package:driver_app/src/features/trip/data/datasources/telemetry_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  test('normalizes the realtime passenger coordinate contract', () async {
    final dio = MockDio();
    final dataSource = TelemetryRemoteDataSourceImpl(dio);
    when(() => dio.get<Map<String, dynamic>>(any())).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/api/v1/telemetry/passenger/303'),
        statusCode: 200,
        data: const {'latitude': 7.828, 'longitude': 123.434},
      ),
    );

    final location = await dataSource.fetchPassengerLocation('303');

    expect(location['lat'], 7.828);
    expect(location['lng'], 123.434);
  });
}
