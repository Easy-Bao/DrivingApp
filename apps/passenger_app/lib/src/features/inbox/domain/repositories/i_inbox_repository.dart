import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/features/inbox/domain/entities/inbox_notification.dart';
import 'package:shared_core/shared_core.dart';

abstract class IInboxRepository {
  Future<Either<Failure, List<InboxNotification>>> fetchPassengerNotifications(
    String passengerId,
  );
}
