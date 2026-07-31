import 'package:core_models/core_models.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/Features/Inbox/Domain/Entities/InboxNotification.dart';

abstract class InboxRepository {
  Future<Either<Failure, List<InboxNotification>>> fetchPassengerNotifications(
    String passengerId,
  );
}
