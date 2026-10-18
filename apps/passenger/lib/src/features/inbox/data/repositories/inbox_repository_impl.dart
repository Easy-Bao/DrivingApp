import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/inbox/data/datasources/inbox_remote_data_source.dart';
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
        final notification = InboxNotification.fromJson(n);
        if (notification.type != 'ride' &&
            notification.type != 'driver' &&
            notification.type != 'chat') {
          continue;
        }
        list.add(notification);
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
      return Err(
        FailureMapper.fromException(
          error,
          serverMessage: 'Notifications are temporarily unavailable.',
        ),
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
    } catch (error) {
      return Err(
        FailureMapper.fromException(
          error,
          serverMessage: 'The message could not be deleted.',
        ),
      );
    }
  }
}
