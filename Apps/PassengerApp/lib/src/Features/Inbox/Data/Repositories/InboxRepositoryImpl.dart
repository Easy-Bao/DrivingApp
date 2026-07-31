import 'package:core_models/core_models.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/Features/Inbox/Domain/Entities/InboxNotification.dart';
import 'package:passenger_app/src/Features/Inbox/Domain/Repositories/InboxRepository.dart';


class InboxRepositoryImpl implements InboxRepository {
  final PassengerRemoteDataSource remoteDataSource;

  InboxRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<InboxNotification>>> fetchPassengerNotifications(
    String passengerId,
  ) async {
    try {
      final rawNotifications = await remoteDataSource.fetchNotifications(
        passengerId,
      );
      final List<InboxNotification> list = [];

      for (final n in rawNotifications) {
        if (n is Map<String, dynamic>) {
          final type = n['type'] as String? ?? 'system';
          if (type != 'ride' && type != 'driver' && type != 'chat') {
            continue;
          }

          final id = n['id'] as String? ?? '';
          final title = n['title'] as String? ?? '';
          final message = n['message'] as String? ?? '';
          final isRead = n['isRead'] as bool? ?? false;
          final dt =
              DateTime.tryParse(n['timestamp'] as String? ?? '') ??
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
      }

      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return Right(list);
    } catch (error) {
      return Left(ServerFailure('Failed to fetch notifications: $error'));
    }
  }
}
