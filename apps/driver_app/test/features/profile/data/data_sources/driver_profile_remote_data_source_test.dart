import 'package:dio/dio.dart';
import 'package:driver_app/src/features/profile/data/data_sources/driver_profile_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  test(
    'updates the authenticated driver through the shared profile contract',
    () async {
      final dio = _MockDio();
      final dataSource = DriverProfileRemoteDataSourceImpl(dio);
      when(
        () => dio.patch<Map<String, dynamic>>(
          any(),
          data: any<dynamic>(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/api/v1/users/me'),
          statusCode: 200,
          data: const {
            'name': 'Updated Driver',
            'phone': '+639170000001',
            'email': 'updated@example.com',
            'vehicle_type': 'Sedan',
            'plate_number': 'ABC-1234',
          },
        ),
      );

      final response = await dataSource.updateProfile(
        data: const {
          'name': 'Updated Driver',
          'phone': '+639170000001',
          'email': 'updated@example.com',
          'vehicle_type': 'Sedan',
          'plate_number': 'ABC-1234',
        },
      );

      expect(response['name'], 'Updated Driver');
      verify(
        () => dio.patch<Map<String, dynamic>>(
          '/api/v1/users/me',
          data: <String, dynamic>{
            'name': 'Updated Driver',
            'phone': '+639170000001',
            'email': 'updated@example.com',
            'vehicle_type': 'Sedan',
            'plate_number': 'ABC-1234',
          },
        ),
      ).called(1);
    },
  );
}
