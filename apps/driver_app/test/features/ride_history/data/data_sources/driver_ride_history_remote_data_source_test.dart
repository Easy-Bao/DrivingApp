import 'package:dio/dio.dart';
import 'package:driver_app/src/features/ride_history/data/data_sources/driver_ride_history_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  test('requests only active trips for dashboard recovery', () async {
    final dio = MockDio();
    final dataSource = DriverRideHistoryRemoteDataSourceImpl(dio);
    when(
      () => dio.get<Map<String, dynamic>>(
        any(),
        queryParameters: any<Map<String, dynamic>>(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/api/v1/drivers/7/trips'),
        statusCode: 200,
        data: const {
          'items': [
            {'id': 3, 'status': 'accepted'},
          ],
          'has_more': false,
          'next_offset': null,
        },
      ),
    );

    final page = await dataSource.fetchTripHistory(
      '7',
      limit: 10,
      activeOnly: true,
    );

    expect(page.items.single['status'], 'accepted');
    verify(
      () => dio.get<Map<String, dynamic>>(
        '/api/v1/drivers/7/trips',
        queryParameters: <String, dynamic>{
          'limit': 10,
          'offset': 0,
          'scope': 'active',
        },
      ),
    ).called(1);
  });

  test('rejects malformed trip items', () async {
    final dio = MockDio();
    final dataSource = DriverRideHistoryRemoteDataSourceImpl(dio);
    when(
      () => dio.get<Map<String, dynamic>>(
        any(),
        queryParameters: any<Map<String, dynamic>>(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/api/v1/drivers/7/trips'),
        statusCode: 200,
        data: const {
          'items': ['malformed'],
          'has_more': false,
          'next_offset': null,
        },
      ),
    );

    expect(() => dataSource.fetchTripHistory('7'), throwsFormatException);
  });
}
