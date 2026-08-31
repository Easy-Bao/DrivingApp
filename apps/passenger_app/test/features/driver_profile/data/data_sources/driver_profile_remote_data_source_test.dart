import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/features/driver_profile/data/data_sources/driver_profile_remote_data_source.dart';

class MockDio extends Mock implements Dio {}

void main() {
  test(
    'normalizes driver review objects at the data-source boundary',
    () async {
      final dio = MockDio();
      final dataSource = DriverProfileRemoteDataSourceImpl(dio);
      when(
        () => dio.get<List<dynamic>>(
          '/api/v1/drivers/42/reviews',
          queryParameters: {'offset': 0, 'limit': 20},
        ),
      ).thenAnswer(
        (_) async => Response<List<dynamic>>(
          requestOptions: RequestOptions(path: '/api/v1/drivers/42/reviews'),
          statusCode: 200,
          data: <dynamic>[
            <String, dynamic>{'id': 1},
            'malformed review',
            <String, dynamic>{'id': 2},
          ],
        ),
      );

      final result = await dataSource.fetchReviews('42');

      expect(result, <Map<String, dynamic>>[
        <String, dynamic>{'id': 1},
        <String, dynamic>{'id': 2},
      ]);
    },
  );

  test('accepts the created response from driver review submission', () async {
    final dio = MockDio();
    final dataSource = DriverProfileRemoteDataSourceImpl(dio);
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

    final submitted = await dataSource.submitReview(
      driverId: '42',
      rideId: '303',
      rating: 5,
      comment: 'Safe trip',
    );

    expect(submitted, isTrue);
  });
}
