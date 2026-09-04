import 'package:dio/dio.dart';
import 'package:foundation/foundation.dart';

abstract class InboxRemoteDataSource {
  Future<OffsetPage<Map<String, dynamic>>> fetchNotifications(
    String passengerId, {
    int limit = 50,
    int offset = 0,
  });

  Future<void> deleteNotification(String passengerId, String notificationId);
}

class InboxRemoteDataSourceImpl(this._dio) implements InboxRemoteDataSource {
  final Dio _dio;

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
      (value) =>
          decodeObjectMap(value, message: 'Notification item is invalid.'),
    );
  }

  @override
  Future<void> deleteNotification(
    String passengerId,
    String notificationId,
  ) async {
    await _dio.delete<void>(
      '/api/v1/passengers/${Uri.encodeComponent(passengerId)}/notifications/${Uri.encodeComponent(notificationId)}',
    );
  }
}
