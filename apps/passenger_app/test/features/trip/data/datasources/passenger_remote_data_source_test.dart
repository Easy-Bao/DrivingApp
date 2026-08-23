import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/features/trip/data/datasources/passenger_remote_data_source.dart';

class MockDio extends Mock implements Dio {}

void main() {
  test('decodes paginated ride history with explicit query bounds', () async {
    final dio = MockDio();
    final dataSource = PassengerRemoteDataSourceImpl(dio);
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

  test('uses the server PUT contract for passenger profile updates', () async {
    final dio = MockDio();
    final dataSource = PassengerRemoteDataSourceImpl(dio);
    when(
      () => dio.put<Map<String, dynamic>>(
        any(),
        data: any<dynamic>(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/api/v1/passengers/42'),
        statusCode: 200,
        data: const {'id': 42, 'name': 'Passenger'},
      ),
    );

    final response = await dataSource.updateProfile(
      passengerId: '42',
      data: {'name': 'Passenger'},
    );

    expect(response['id'], 42);
    verify(
      () => dio.put<Map<String, dynamic>>(
        '/api/v1/passengers/42',
        data: <String, dynamic>{'name': 'Passenger'},
      ),
    ).called(1);
    verifyNever(
      () => dio.patch<Map<String, dynamic>>(
        any(),
        data: any<dynamic>(named: 'data'),
      ),
    );
  });

  test('loads the passenger activity aggregate independently', () async {
    final dio = MockDio();
    final dataSource = PassengerRemoteDataSourceImpl(dio);
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

    final summary = await dataSource.fetchActivitySummary('42');

    expect(summary['this_week_completed_rides'], 6);
    verify(
      () => dio.get<Map<String, dynamic>>(
        '/api/v1/passengers/42/activity-summary',
      ),
    ).called(1);
  });
}
