import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/features/home/data/data_sources/public_driver_remote_data_source.dart';

class MockDio extends Mock implements Dio {}

void main() {
  test(
    'normalizes public driver objects at the data-source boundary',
    () async {
      final dio = MockDio();
      final dataSource = PublicDriverRemoteDataSourceImpl(dio);
      when(
        () => dio.get<List<dynamic>>(
          '/api/v1/drivers/public/summaries',
          queryParameters: {'limit': 5},
        ),
      ).thenAnswer(
        (_) async => Response<List<dynamic>>(
          requestOptions: RequestOptions(
            path: '/api/v1/drivers/public/summaries',
          ),
          statusCode: 200,
          data: <dynamic>[
            <String, dynamic>{'id': 1},
            'malformed item',
            <String, dynamic>{'id': 2},
          ],
        ),
      );

      final result = await dataSource.fetchSummaries();

      expect(result, <Map<String, dynamic>>[
        <String, dynamic>{'id': 1},
        <String, dynamic>{'id': 2},
      ]);
    },
  );
}
