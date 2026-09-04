import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/features/inbox/data/data_sources/inbox_remote_data_source.dart';

class MockDio extends Mock implements Dio {}

void main() {
  test(
    'deletes a notification through the passenger-scoped endpoint',
    () async {
      final dio = MockDio();
      final dataSource = InboxRemoteDataSourceImpl(dio);
      when(() => dio.delete<void>(any())).thenAnswer(
        (_) async => Response<void>(
          requestOptions: RequestOptions(
            path: '/api/v1/passengers/42/notifications/7',
          ),
          statusCode: 204,
        ),
      );

      await dataSource.deleteNotification('42', '7');

      verify(() => dio.delete<void>('/api/v1/passengers/42/notifications/7'))
          .called(1);
    },
  );

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
