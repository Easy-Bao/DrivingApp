import 'package:core_models/core_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/features/auth/data/data_sources/auth_remote_data_source.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late AuthRemoteDataSourceImpl dataSource;

  setUp(() {
    dio = MockDio();
    dataSource = AuthRemoteDataSourceImpl(dio);
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
  });
}
