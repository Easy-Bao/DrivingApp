import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/features/inbox/data/datasources/inbox_remote_data_source.dart';
import 'package:passenger_app/src/features/inbox/domain/entities/inbox_notification.dart';
import 'package:passenger_app/src/features/inbox/domain/repositories/i_inbox_repository.dart';
import 'package:shared_core/shared_core.dart';

class InboxRepository implements IInboxRepository, IPaginatedInboxRepository {
  final InboxRemoteDataSource remoteDataSource;

  InboxRepository({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<InboxNotification>>> fetchPassengerNotifications(
    String passengerId,
  ) async {
    final result = await fetchPassengerNotificationsPage(passengerId);
    return result.map((page) => page.items);
  }

  @override
  Future<Either<Failure, OffsetPage<InboxNotification>>>
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
      return Right(
        OffsetPage<InboxNotification>(
          items: list,
          hasMore: notificationPage.hasMore,
          nextOffset: notificationPage.nextOffset,
        ),
      );
    } catch (error) {
      return const Left(
        ServerFailure('Notifications are temporarily unavailable.'),
      );
    }
  }

  bool _toBool(Object? value) {
    if (value is bool) return value;
    return value?.toString().toLowerCase() == 'true';
  }
}
