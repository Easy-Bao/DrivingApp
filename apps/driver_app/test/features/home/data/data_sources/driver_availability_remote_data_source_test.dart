import 'package:dio/dio.dart';
import 'package:driver_app/src/features/home/data/data_sources/driver_availability_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  test(
    'sends only the online state accepted by the availability API',
    () async {
      final dio = MockDio();
      final dataSource = DriverAvailabilityRemoteDataSourceImpl(dio);
      when(
        () => dio.post<Map<String, dynamic>>(
          any(),
          data: any<dynamic>(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/api/v1/drivers/42/online'),
          statusCode: 200,
        ),
      );

      await dataSource.updateOnlineStatus(driverId: '42', isOnline: true);

      verify(
        () => dio.post<Map<String, dynamic>>(
          '/api/v1/drivers/42/online',
          data: <String, dynamic>{'is_online': true},
        ),
      ).called(1);
    },
  );
}
