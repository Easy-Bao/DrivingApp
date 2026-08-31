import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/features/profile/data/data_sources/passenger_profile_remote_data_source.dart';

class MockDio extends Mock implements Dio {}

void main() {
  test('uses the server PUT contract for passenger profile updates', () async {
    final dio = MockDio();
    final dataSource = PassengerProfileRemoteDataSourceImpl(dio);
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

  test('uploads and fetches the authenticated passenger avatar', () async {
    final dio = MockDio();
    final dataSource = PassengerProfileRemoteDataSourceImpl(dio);
    when(
      () => dio.post<void>(any(), data: any<dynamic>(named: 'data')),
    ).thenAnswer(
      (_) async => Response<void>(
        requestOptions: RequestOptions(path: '/api/v1/passengers/42/avatar'),
        statusCode: 200,
      ),
    );
    when(
      () => dio.get<List<int>>(any(), options: any(named: 'options')),
    ).thenAnswer(
      (_) async => Response<List<int>>(
        requestOptions: RequestOptions(path: '/api/v1/passengers/42/avatar'),
        statusCode: 200,
        data: const [1, 2, 3],
      ),
    );

    await dataSource.uploadProfileAvatar(
      passengerId: '42',
      bytes: const [1, 2, 3],
      fileName: 'profile.png',
    );
    final bytes = await dataSource.fetchProfileAvatar('42');

    expect(bytes, const [1, 2, 3]);
    final postInvocation =
        verify(
              () => dio.post<void>(
                '/api/v1/passengers/42/avatar',
                data: captureAny(named: 'data'),
              ),
            ).captured.single
            as FormData;
    expect(postInvocation.files.single.key, 'photo');
    expect(postInvocation.files.single.value.filename, 'profile.png');
    verify(
      () => dio.get<List<int>>(
        '/api/v1/passengers/42/avatar',
        options: any(named: 'options'),
      ),
    ).called(1);
  });
}
