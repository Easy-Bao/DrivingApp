import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:shared_core/shared_core.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late AuthRemoteDataSourceImpl dataSource;

  setUp(() {
    dio = MockDio();
    dataSource = AuthRemoteDataSourceImpl(dio);
  });

  test('returns the verified session payload from the OTP route', () async {
    when(
      () => dio.post<Object?>(any(), data: any<dynamic>(named: 'data')),
    ).thenAnswer(
      (_) async => Response<Object?>(
        requestOptions: RequestOptions(path: '/auth/verify-otp'),
        statusCode: 200,
        data: <String, dynamic>{
          'success': true,
          'data': <String, dynamic>{
            'verified': true,
            'token': 'jwt-token',
            'user': <String, dynamic>{'id': 42},
          },
        },
      ),
    );

    final result = await dataSource.verifyOtp(
      email: 'passenger@example.com',
      code: '123456',
    );

    expect(result['token'], 'jwt-token');
    expect(result['user'], <String, dynamic>{'id': 42});
    verify(
      () => dio.post<Object?>(
        '/auth/verify-otp',
        data: <String, dynamic>{
          'email': 'passenger@example.com',
          'code': '123456',
        },
      ),
    ).called(1);
  });

  group('AuthRemoteDataSourceImpl.loginPassenger', () {
    test('posts the credentials to the passenger login route', () async {
      const email = 'passenger@example.com';
      const password = 'secret-password';

      when(
        () => dio.post<Object?>(any(), data: any<dynamic>(named: 'data')),
      ).thenAnswer(
        (_) async => Response<Object?>(
          requestOptions: RequestOptions(path: '/auth/passenger/login'),
          statusCode: 200,
          data: <String, dynamic>{
            'success': true,
            'data': <String, dynamic>{
              'token': 'jwt-token',
              'user': <String, dynamic>{'id': 'passenger-42'},
              'needsVerification': false,
            },
          },
        ),
      );

      await dataSource.loginPassenger(email: email, password: password);

      verify(
        () => dio.post<Object?>(
          '/auth/passenger/login',
          data: <String, dynamic>{'email': email, 'password': password},
        ),
      ).called(1);
    });

    test('unwraps the server data envelope', () async {
      const email = 'passenger@example.com';
      const password = 'secret-password';
      final sessionPayload = <String, dynamic>{
        'token': 'jwt-token',
        'user': <String, dynamic>{
          'id': 'passenger-42',
          'name': 'Test Passenger',
          'email': email,
          'phone': '+639170000001',
        },
        'needsVerification': false,
      };

      when(
        () => dio.post<Object?>(any(), data: any<dynamic>(named: 'data')),
      ).thenAnswer(
        (_) async => Response<Object?>(
          requestOptions: RequestOptions(path: '/auth/passenger/login'),
          statusCode: 200,
          data: <String, dynamic>{'success': true, 'data': sessionPayload},
        ),
      );

      final result = await dataSource.loginPassenger(
        email: email,
        password: password,
      );

      expect(result, sessionPayload);
    });

    test(
      'rejects a successful response whose data payload is malformed',
      () async {
        when(
          () => dio.post<Object?>(any(), data: any<dynamic>(named: 'data')),
        ).thenAnswer(
          (_) async => Response<Object?>(
            requestOptions: RequestOptions(path: '/auth/passenger/login'),
            statusCode: 200,
            data: <String, dynamic>{
              'success': true,
              'data': 'not-an-auth-session',
            },
          ),
        );

        expect(
          () => dataSource.loginPassenger(
            email: 'passenger@example.com',
            password: 'secret-password',
          ),
          throwsA(isA<DataParsingException>()),
        );
      },
    );

    test('hides internal diagnostics from server failures', () async {
      when(
        () => dio.post<Object?>(any(), data: any<dynamic>(named: 'data')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/passenger/login'),
          response: Response<Object?>(
            requestOptions: RequestOptions(path: '/auth/passenger/login'),
            statusCode: 500,
            data: <String, dynamic>{
              'message': 'Failed query: select * from passengers',
            },
          ),
        ),
      );

      expect(
        () => dataSource.loginPassenger(
          email: 'passenger@example.com',
          password: 'secret-password',
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
  });
}
