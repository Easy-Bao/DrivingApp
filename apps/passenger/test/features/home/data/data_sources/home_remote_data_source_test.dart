import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/features/home/data/data_sources/home_remote_data_source.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  test('requests home data from the canonical passenger route', () async {
    final dio = _MockDio();
    final dataSource = HomeRemoteDataSourceImpl(dio);
    when(
      () => dio.get<Map<String, dynamic>>(
        any(),
        queryParameters: any<Map<String, dynamic>>(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/api/v1/passengers/me/home'),
        statusCode: 200,
        data: const <String, dynamic>{'recent_locations': <dynamic>[]},
      ),
    );

    final result = await dataSource.fetchHomeData(lat: 14.5, lng: 121);

    expect(result, <String, dynamic>{'recent_locations': <dynamic>[]});
    verify(
      () => dio.get<Map<String, dynamic>>(
        '/api/v1/passengers/me/home',
        queryParameters: <String, dynamic>{'lat': 14.5, 'lng': 121},
      ),
    ).called(1);
  });
}
