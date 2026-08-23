import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/features/driver_profile/data/datasources/driver_profile_remote_data_source.dart';

class MockDio extends Mock implements Dio {}

void main() {
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
