import 'package:dio/dio.dart';
import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/inbox/data/data_sources/inbox_remote_data_source.dart';
import 'package:passenger/src/features/inbox/domain/entities/inbox_notification.dart';
import 'package:passenger/src/features/inbox/domain/repositories/inbox_repository.dart';

final class InboxRepositoryImpl({required this.remoteDataSource})
    implements
        InboxRepository,
        PaginatedInboxRepository,
        DismissibleInboxRepository {
  final InboxRemoteDataSource remoteDataSource;

  @override
  Future<Result<List<InboxNotification>, Failure>> fetchPassengerNotifications(
    String passengerId,
  ) async {
    final result = await fetchPassengerNotificationsPage(passengerId);
    return result.map((page) => page.items);
  }

  @override
  Future<Result<OffsetPage<InboxNotification>, Failure>>
  fetchPassengerNotificationsPage(
    String passengerId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final notificationPage = await remoteDataSource.fetchNotifications(
        passengerId,
        limit: limit,
        offset: offset,
      );
      final List<InboxNotification> list = [];

      for (final n in notificationPage.items) {
        final type = SafeParse.toStringValue(n['type'], 'system');
        if (type != 'ride' && type != 'driver' && type != 'chat') {
          continue;
        }

        final id = SafeParse.toStringValue(n['id']);
        final title = SafeParse.toStringValue(n['title']);
        final message = SafeParse.toStringValue(n['message'] ?? n['body']);
        final isRead = _toBool(n['isRead'] ?? n['is_read']);
        final dt =
            DateTime.tryParse(
              SafeParse.toStringValue(n['timestamp'] ?? n['created_at']),
            ) ??
            DateTime.now();

        list.add(
          InboxNotification(
            id: id,
            title: title,
            message: message,
            timestamp: dt,
            type: type,
            isRead: isRead,
          ),
        );
      }

      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return Ok(
        OffsetPage<InboxNotification>(
          items: list,
          hasMore: notificationPage.hasMore,
          nextOffset: notificationPage.nextOffset,
        ),
      );
    } catch (error) {
      return const Err(
        ServerFailure('Notifications are temporarily unavailable.'),
      );
    }
  }

  @override
  Future<Result<void, Failure>> deletePassengerNotification(
    String passengerId,
    String notificationId,
  ) async {
    try {
      await remoteDataSource.deleteNotification(passengerId, notificationId);
      return const Ok(null);
    } on DioException catch (error) {
      return Err(
        ServerFailure.withStatusCode(
          'The message could not be deleted.',
          error.response?.statusCode ?? 500,
        ),
      );
    } catch (_) {
      return const Err(ServerFailure('The message could not be deleted.'));
    }
  }

  bool _toBool(Object? value) {
    if (value is bool) return value;
    return value?.toString().toLowerCase() == 'true';
  }
}
