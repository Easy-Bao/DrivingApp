import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/features/inbox/data/datasources/inbox_remote_data_source.dart';
import 'package:passenger/src/features/inbox/data/repositories/inbox_repository_impl.dart';
import 'package:passenger/src/features/inbox/domain/entities/inbox_notification.dart';

class MockInboxRemoteDataSource extends Mock implements InboxRemoteDataSource {}

void main() {
  test(
    'fetchPassengerNotificationsPage preserves chat deep-link fields',
    () async {
      final remoteDataSource = MockInboxRemoteDataSource();
      final repository = InboxRepositoryImpl(
        remoteDataSource: remoteDataSource,
      );

      when(
        () => remoteDataSource.fetchNotifications(
          'passenger-1',
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer(
        (_) async => const OffsetPage<Map<String, dynamic>>(
          items: [
            {
              'id': 'notif-1',
              'title': 'New Chat Message',
              'message': 'Driver is here',
              'timestamp': '2026-01-01T12:00:00Z',
              'type': 'chat',
              'is_read': false,
              'room_id': 'room-123',
              'peer_id': 'driver-456',
              'peer_name': 'Driver Dave',
              'user_id': 'passenger-1',
            },
          ],
          hasMore: false,
          nextOffset: null,
        ),
      );

      final result = await repository.fetchPassengerNotificationsPage(
        'passenger-1',
      );
      late final OffsetPage<InboxNotification> page;
      result.fold(
        (failure) => fail('expected Ok, got: $failure'),
        (value) => page = value,
      );
      expect(page.items.length, 1);
      final notification = page.items.first;
      expect(notification.id, 'notif-1');
      expect(notification.roomId, 'room-123');
      expect(notification.peerId, 'driver-456');
      expect(notification.peerName, 'Driver Dave');
      expect(notification.userId, 'passenger-1');
    },
  );
}
