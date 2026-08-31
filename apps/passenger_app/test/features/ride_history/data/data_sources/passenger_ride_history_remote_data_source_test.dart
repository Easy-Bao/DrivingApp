import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/features/ride_history/data/data_sources/passenger_ride_history_remote_data_source.dart';

class MockDio extends Mock implements Dio {}

void main() {
  test('decodes paginated ride history with explicit query bounds', () async {
    final dio = MockDio();
    final dataSource = PassengerRideHistoryRemoteDataSourceImpl(dio);
    when(
      () => dio.get<Map<String, dynamic>>(
        any(),
        queryParameters: any<Map<String, dynamic>>(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/api/v1/passengers/42/rides'),
        statusCode: 200,
        data: const {
          'items': [
            {'id': 7},
          ],
          'has_more': true,
          'next_offset': 25,
        },
      ),
    );

    final page = await dataSource.fetchRideHistory('42', limit: 25, offset: 0);

    expect(page.items.single['id'], 7);
    expect(page.hasMore, isTrue);
    expect(page.nextOffset, 25);
    verify(
      () => dio.get<Map<String, dynamic>>(
        '/api/v1/passengers/42/rides',
        queryParameters: <String, dynamic>{'limit': 25, 'offset': 0},
      ),
    ).called(1);
  });

  test('loads the passenger activity aggregate independently', () async {
    final dio = MockDio();
    final dataSource = PassengerRideHistoryRemoteDataSourceImpl(dio);
    when(() => dio.get<Map<String, dynamic>>(any())).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(
          path: '/api/v1/passengers/42/activity-summary',
        ),
        statusCode: 200,
        data: const {
          'this_week_fare_centavos': 21426,
          'this_week_completed_rides': 6,
        },
      ),
    );

    final summary = await dataSource.fetchSummary('42');

    expect(summary['this_week_completed_rides'], 6);
    verify(
      () => dio.get<Map<String, dynamic>>(
        '/api/v1/passengers/42/activity-summary',
      ),
    ).called(1);
  });

  test('rejects malformed ride history items', () async {
    final dio = MockDio();
    final dataSource = PassengerRideHistoryRemoteDataSourceImpl(dio);
    when(
      () => dio.get<Map<String, dynamic>>(
        any(),
        queryParameters: any<Map<String, dynamic>>(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/api/v1/passengers/42/rides'),
        statusCode: 200,
        data: const {
          'items': ['malformed'],
          'has_more': false,
          'next_offset': null,
        },
      ),
    );

    expect(() => dataSource.fetchRideHistory('42'), throwsFormatException);
  });
}
