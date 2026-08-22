import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/features/trip/data/datasources/passenger_remote_data_source.dart';

class MockDio extends Mock implements Dio {}

void main() {
  test('uses the server PUT contract for passenger profile updates', () async {
    final dio = MockDio();
    final dataSource = PassengerRemoteDataSourceImpl(dio);
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
}
