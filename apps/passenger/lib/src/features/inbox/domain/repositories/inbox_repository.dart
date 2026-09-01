import 'package:foundation/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger/src/features/inbox/domain/entities/inbox_notification.dart';

abstract interface class InboxRepository {
  Future<Either<Failure, List<InboxNotification>>> fetchPassengerNotifications(
    String passengerId,
  );
}

abstract interface class PaginatedInboxRepository {
  Future<Either<Failure, OffsetPage<InboxNotification>>>
  fetchPassengerNotificationsPage(
    String passengerId, {
    int limit = 50,
    int offset = 0,
  });
}
