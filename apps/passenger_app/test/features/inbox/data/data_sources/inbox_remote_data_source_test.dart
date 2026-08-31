import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/features/inbox/data/data_sources/inbox_remote_data_source.dart';

class MockDio extends Mock implements Dio {}

void main() {
  test('rejects malformed notification items', () async {
    final dio = MockDio();
    final dataSource = InboxRemoteDataSourceImpl(dio);
    when(
      () => dio.get<Map<String, dynamic>>(
        any(),
        queryParameters: any<Map<String, dynamic>>(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(
          path: '/api/v1/passengers/42/notifications',
        ),
        statusCode: 200,
        data: const {
          'items': ['malformed'],
          'has_more': false,
          'next_offset': null,
        },
      ),
    );

    expect(() => dataSource.fetchNotifications('42'), throwsFormatException);
  });
}
