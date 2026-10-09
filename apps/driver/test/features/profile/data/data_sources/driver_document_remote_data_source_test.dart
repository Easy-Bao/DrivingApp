import 'package:dio/dio.dart';
import 'package:driver/src/features/profile/data/data_sources/driver_document_remote_data_source.dart';
import 'package:driver/src/features/profile/domain/entities/driver_document.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

class _FakeOptions extends Fake implements Options {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeOptions()));

  test('uploads documents through the canonical driver route', () async {
    final dio = _MockDio();
    final dataSource = DriverDocumentRemoteDataSourceImpl(dio);
    when(
      () => dio.post<Map<String, dynamic>>(
        any(),
        queryParameters: any<Map<String, dynamic>>(named: 'queryParameters'),
        data: any<dynamic>(named: 'data'),
        options: any<Options>(named: 'options'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/api/v1/drivers/me/documents'),
        statusCode: 201,
        data: const <String, dynamic>{
          'id': 12,
          'document_type': 'driver_license',
          'status': 'pending',
          'content_type': 'application/pdf',
        },
      ),
    );
    final bytes = <int>[37, 80, 68, 70];

    final result = await dataSource.upload(
      type: DriverDocumentType.driverLicense,
      bytes: bytes,
      contentType: 'application/pdf',
    );

    expect(result.id, 12);
    verify(
      () => dio.post<Map<String, dynamic>>(
        '/api/v1/drivers/me/documents',
        queryParameters: <String, dynamic>{'type': 'driver_license'},
        data: bytes,
        options: any<Options>(named: 'options'),
      ),
    ).called(1);
  });
}
