import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:driver_app/src/core/constants/api_endpoints.dart';
import 'package:driver_app/src/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:shared_core/shared_core.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late AuthRemoteDataSourceImpl dataSource;

  setUp(() {
    dio = MockDio();
    dataSource = AuthRemoteDataSourceImpl(dio);
  });

  test(
    'unwraps the driver session envelope and preserves numeric IDs',
    () async {
      when(
        () => dio.post<Object?>(any(), data: any<dynamic>(named: 'data')),
      ).thenAnswer(
        (_) async => Response<Object?>(
          requestOptions: RequestOptions(path: ApiEndpoints.driverLogin),
          statusCode: 200,
          data: <String, dynamic>{
            'success': true,
            'data': <String, dynamic>{
              'token': 'jwt-token',
              'user': <String, dynamic>{'id': 42, 'role': 'driver'},
            },
          },
        ),
      );

      final result = await dataSource.authenticateDriver(
        email: 'driver@example.com',
        password: 'secret-password',
      );

      expect(result['token'], 'jwt-token');
      expect(result['user'], <String, dynamic>{'id': 42, 'role': 'driver'});
      verify(
        () => dio.post<Object?>(
          ApiEndpoints.driverLogin,
          data: <String, dynamic>{
            'email': 'driver@example.com',
            'password': 'secret-password',
          },
        ),
      ).called(1);
    },
  );

  test(
    'rejects a successful response with an invalid session envelope',
    () async {
      when(
        () => dio.post<Object?>(any(), data: any<dynamic>(named: 'data')),
      ).thenAnswer(
        (_) async => Response<Object?>(
          requestOptions: RequestOptions(path: ApiEndpoints.driverLogin),
          statusCode: 200,
          data: <String, dynamic>{'success': true, 'data': 'invalid'},
        ),
      );

      expect(
        () => dataSource.authenticateDriver(
          email: 'driver@example.com',
          password: 'secret-password',
        ),
        throwsA(isA<DataParsingException>()),
      );
    },
  );
}
