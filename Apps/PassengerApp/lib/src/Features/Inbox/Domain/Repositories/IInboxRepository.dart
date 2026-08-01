import 'package:core_models/CoreModels.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/Features/Inbox/Domain/Entities/InboxNotification.dart';

abstract class IInboxRepository {
  Future<Either<Failure, List<InboxNotification>>> fetchPassengerNotifications(
    String passengerId,
  );
}
