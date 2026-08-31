import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/features/trip/data/data_sources/booking_remote_data_source.dart';

class MockDio extends Mock implements Dio {}

void main() {
  test(
    'normalizes booking offer objects at the data-source boundary',
    () async {
      final dio = MockDio();
      final dataSource = BookingRemoteDataSourceImpl(dio);
      when(
        () => dio.get<List<dynamic>>('/api/v1/bids/session-1/offers'),
      ).thenAnswer(
        (_) async => Response<List<dynamic>>(
          requestOptions: RequestOptions(path: '/api/v1/bids/session-1/offers'),
          statusCode: 200,
          data: <dynamic>[
            <String, dynamic>{'id': 1},
            'malformed offer',
            <String, dynamic>{'id': 2},
          ],
        ),
      );

      final result = await dataSource.fetchOffers('session-1');

      expect(result, <Map<String, dynamic>>[
        <String, dynamic>{'id': 1},
        <String, dynamic>{'id': 2},
      ]);
    },
  );
}
