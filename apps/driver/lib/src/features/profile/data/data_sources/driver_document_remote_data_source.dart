import 'package:dio/dio.dart';

import 'package:driver/src/features/profile/domain/entities/driver_document.dart';

abstract interface class DriverDocumentRemoteDataSource {
  Future<DriverDocument> upload({
    required DriverDocumentType type,
    required List<int> bytes,
    required String contentType,
  });
}

final class DriverDocumentRemoteDataSourceImpl
    implements DriverDocumentRemoteDataSource {
  const DriverDocumentRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<DriverDocument> upload({
    required DriverDocumentType type,
    required List<int> bytes,
    required String contentType,
  }) async {
    final path = Uri(
      pathSegments: <String>[
        '',
        'api',
        'v1',
        'drivers',
        'me',
        'documents',
        type.apiValue,
      ],
    ).toString();
    final response = await _dio.post<Map<String, dynamic>>(
      path,
      data: FormData.fromMap(<String, dynamic>{
        'document': MultipartFile.fromBytes(
          bytes,
          filename: type.apiValue,
          contentType: DioMediaType.parse(contentType),
        ),
      }),
    );
    return DriverDocument.fromJson(response.data ?? const <String, dynamic>{});
  }
}
