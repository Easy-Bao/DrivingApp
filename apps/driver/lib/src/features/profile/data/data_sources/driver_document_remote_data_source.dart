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
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/driver/documents',
      queryParameters: <String, dynamic>{'type': type.queryValue},
      data: bytes,
      options: Options(contentType: contentType),
    );
    return DriverDocument.fromJson(response.data ?? const <String, dynamic>{});
  }
}
