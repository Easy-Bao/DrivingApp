import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/inbox/domain/entities/inbox_notification.dart';

abstract interface class InboxRepository {
  Future<Result<List<InboxNotification>, Failure>> fetchPassengerNotifications(
    String passengerId,
  );
}

abstract interface class PaginatedInboxRepository {
  Future<Result<OffsetPage<InboxNotification>, Failure>>
  fetchPassengerNotificationsPage(
    String passengerId, {
    int limit = 50,
    int offset = 0,
  });
}

abstract interface class DismissibleInboxRepository {
  Future<Result<void, Failure>> deletePassengerNotification(
    String passengerId,
    String notificationId,
  );
}
