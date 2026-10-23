import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/features/driver_profile/data/datasources/driver_profile_remote_data_source.dart';

class MockDio extends Mock implements Dio {}

void main() {
  test('preserves review cursor metadata from the server', () async {
    final dio = MockDio();
    final dataSource = DriverProfileRemoteDataSourceImpl(dio);
    when(
      () => dio.get<Object?>(
        any(),
        queryParameters: any<Map<String, dynamic>>(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response<Object?>(
        requestOptions: RequestOptions(path: '/api/v1/drivers/42/reviews'),
        data: const {
          'items': [
            {'id': 1},
          ],
          'has_more': true,
          'next_offset': null,
          'next_cursor': 'next-boundary',
        },
      ),
    );
    final page = await dataSource.fetchReviews(
      '42',
      cursor: 'previous-boundary',
      limit: 3,
    );
    expect(page.items.single['id'], 1);
    expect(page.nextCursor, 'next-boundary');
    expect(page.hasMore, isTrue);
    verify(
      () => dio.get<Object?>(
        '/api/v1/drivers/42/reviews',
        queryParameters: <String, dynamic>{
          'cursor': 'previous-boundary',
          'limit': 3,
        },
      ),
    ).called(1);
  });

  test(
    'normalizes driver review objects at the data-source boundary',
    () async {
      final dio = MockDio();
      final dataSource = DriverProfileRemoteDataSourceImpl(dio);
      when(
        () => dio.get<Object?>(
          '/api/v1/drivers/42/reviews',
          queryParameters: {'cursor': '', 'limit': 20},
        ),
      ).thenAnswer(
        (_) async => Response<Object?>(
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

      expect(result.items, <Map<String, dynamic>>[
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
