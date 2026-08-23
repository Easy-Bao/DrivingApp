import 'package:dio/dio.dart';
import 'package:shared_core/shared_core.dart';

abstract class InboxRemoteDataSource {
  Future<OffsetPage<Map<String, dynamic>>> fetchNotifications(
    String passengerId, {
    int limit = 50,
    int offset = 0,
  });
}

class InboxRemoteDataSourceImpl implements InboxRemoteDataSource {
  final Dio _dio;

  InboxRemoteDataSourceImpl(this._dio);

  @override
  Future<OffsetPage<Map<String, dynamic>>> fetchNotifications(
    String passengerId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/passengers/${Uri.encodeComponent(passengerId)}/notifications',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    return OffsetPage<Map<String, dynamic>>.fromJson(
      response.data ?? const <String, dynamic>{},
      (value) => Map<String, dynamic>.from(value! as Map),
    );
  }
}
