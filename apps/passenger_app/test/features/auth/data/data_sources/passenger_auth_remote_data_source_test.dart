import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/features/auth/data/data_sources/passenger_auth_remote_data_source.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late PassengerAuthRemoteDataSource dataSource;

  setUp(() {
    dio = _MockDio();
    dataSource = PassengerAuthRemoteDataSourceImpl(dio);
  });

  test('unwraps a successful authentication response', () async {
    when(() => dio.post<Object?>(any(), data: any<dynamic>(named: 'data')))
        .thenAnswer(
          (_) async => Response<Object?>(
            requestOptions: RequestOptions(path: '/auth/login'),
            statusCode: 200,
            data: <String, dynamic>{
              'success': true,
              'data': <String, dynamic>{'token': 'jwt-token'},
            },
          ),
        );

    final result = await dataSource.postData(
      '/auth/login',
      requestBody: <String, dynamic>{
        'email': 'user@example.com',
        'password': 'secret-password',
      },
    );

    expect(result, <String, dynamic>{'token': 'jwt-token'});
  });

  test('rejects a successful response with an invalid data envelope', () async {
    when(() => dio.post<Object?>(any(), data: any<dynamic>(named: 'data')))
        .thenAnswer(
          (_) async => Response<Object?>(
            requestOptions: RequestOptions(path: '/auth/login'),
            statusCode: 200,
            data: <String, dynamic>{'success': true, 'data': 'invalid'},
          ),
        );

    expect(
      () => dataSource.postData(
        '/auth/login',
        requestBody: <String, dynamic>{'email': 'user@example.com'},
      ),
      throwsA(isA<DataParsingException>()),
    );
  });

  test('maps transport failures to safe server exceptions', () async {
    when(() => dio.post<Object?>(any(), data: any<dynamic>(named: 'data')))
        .thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/auth/login'),
            response: Response<Object?>(
              requestOptions: RequestOptions(path: '/auth/login'),
              statusCode: 500,
              data: <String, dynamic>{
                'message': 'Failed query: select * from passengers',
              },
            ),
          ),
        );

    expect(
      () => dataSource.postJson(
        '/auth/login',
        requestBody: <String, dynamic>{'email': 'user@example.com'},
      ),
      throwsA(
        isA<ServerException>().having(
          (exception) => exception.message,
          'message',
          'The authentication service is temporarily unavailable. Please try again.',
        ),
      ),
    );
  });
}
