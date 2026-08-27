import 'package:dio/dio.dart';
import 'package:driver_app/src/features/home/data/datasources/ride_offer_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  test('normalizes active bid objects at the data-source boundary', () async {
    final dio = MockDio();
    final dataSource = RideOfferRemoteDataSourceImpl(dio);
    when(() => dio.get<List<dynamic>>('/api/v1/bids/active')).thenAnswer(
      (_) async => Response<List<dynamic>>(
        requestOptions: RequestOptions(path: '/api/v1/bids/active'),
        statusCode: 200,
        data: <dynamic>[
          <String, dynamic>{'id': 1},
          'malformed item',
          <String, dynamic>{'id': 2},
        ],
      ),
    );

    final result = await dataSource.fetchActiveBids();

    expect(result, <Map<String, dynamic>>[
      <String, dynamic>{'id': 1},
      <String, dynamic>{'id': 2},
    ]);
  });

  test('sends the canonical centavo fare field to the bid endpoint', () async {
    final dio = MockDio();
    final dataSource = RideOfferRemoteDataSourceImpl(dio);
    when(
      () => dio.post<Map<String, dynamic>>(
        any(),
        data: any<dynamic>(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/api/v1/bids/101/offer'),
        statusCode: 201,
        data: const {'id': 7},
      ),
    );

    final submitted = await dataSource.placeBid(
      sessionId: '101',
      offerPrice: 125.50,
    );

    expect(submitted, isTrue);
    verify(
      () => dio.post<Map<String, dynamic>>(
        '/api/v1/bids/101/offer',
        data: <String, dynamic>{'proposed_fare_centavos': 12550},
      ),
    ).called(1);
  });
}
