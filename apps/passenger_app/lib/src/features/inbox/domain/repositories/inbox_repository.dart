import 'package:core_models/core_models.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/features/inbox/domain/entities/inbox_notification.dart';

abstract class InboxRepository {
  Future<Either<Failure, List<InboxNotification>>> fetchPassengerNotifications(
    String passengerId,
  );
}
