import 'package:flutter_test/flutter_test.dart';
import 'package:passenger/src/features/inbox/domain/entities/inbox_notification.dart';
import 'package:passenger/src/features/inbox/presentation/formatters/inbox_presenter.dart';

void main() {
  final referenceTime = DateTime(2026, 11, 22, 15, 30);

  InboxNotification buildNotification({
    String id = '1',
    String title = 'Ride completed',
    String message = 'Your receipt is ready.',
    DateTime? timestamp,
    String type = 'ride',
    bool isRead = false,
    String? roomId,
    String? peerId,
    String? peerName,
    String? userId,
  }) {
    return InboxNotification(
      id: id,
      title: title,
      message: message,
      timestamp: timestamp ?? referenceTime,
      type: type,
      isRead: isRead,
      roomId: roomId,
      peerId: peerId,
      peerName: peerName,
      userId: userId,
    );
  }

  test('categorizes notifications by type and receipt wording', () {
    final presenter = InboxPresenter(referenceTime);

    expect(
      presenter.categoryOf(buildNotification(type: 'chat')),
      InboxNotificationCategory.message,
    );
    expect(
      presenter.categoryOf(buildNotification(type: 'driver')),
      InboxNotificationCategory.message,
    );
    expect(
      presenter.categoryOf(
        buildNotification(
          type: 'ride',
          title: 'Trip receipt',
          message: 'Paid via cash',
        ),
      ),
      InboxNotificationCategory.receipt,
    );
    expect(
      presenter.categoryOf(
        buildNotification(
          type: 'ride',
          title: 'Driver assigned',
          message: 'Your driver is on the way.',
        ),
      ),
      InboxNotificationCategory.ride,
    );
    expect(
      presenter.categoryOf(
        buildNotification(
          type: 'system',
          title: 'Account update',
          message: 'Profile saved.',
        ),
      ),
      InboxNotificationCategory.general,
    );
  });

  test(
    'identifies openable chat notifications only with full room context',
    () {
      final presenter = InboxPresenter(referenceTime);

      expect(
        presenter.isOpenableChat(
          buildNotification(
            type: 'chat',
            roomId: 'room-1',
            userId: 'passenger-1',
            peerId: 'driver-1',
          ),
        ),
        isTrue,
      );
      expect(
        presenter.isOpenableChat(
          buildNotification(type: 'chat', roomId: 'room-1'),
        ),
        isFalse,
      );
      expect(
        presenter.isOpenableChat(
          buildNotification(
            type: 'ride',
            roomId: 'room-1',
            userId: 'passenger-1',
            peerId: 'driver-1',
          ),
        ),
        isFalse,
      );
    },
  );

  test('trims legacy expiry suffix from no nearby driver notifications', () {
    final presenter = InboxPresenter(referenceTime);
    final notification = buildNotification(
      title: 'No nearby driver found',
      message: 'We could not match a driver. Your request has expired. Please try searching again.',
    );

    expect(
      presenter.normalizedMessage(notification),
      'We could not match a driver.',
    );
  });

  test('filters by all, unread, messages, and rides', () {
    final presenter = InboxPresenter(referenceTime);
    final notifications = [
      buildNotification(id: '1', type: 'chat', isRead: false),
      buildNotification(id: '2', type: 'driver', isRead: true),
      buildNotification(id: '3', type: 'ride', isRead: false),
    ];

    expect(presenter.unreadCount(notifications), 2);
    expect(presenter.filter(notifications, InboxFilter.all).map((n) => n.id), [
      '1',
      '2',
      '3',
    ]);
    expect(
      presenter.filter(notifications, InboxFilter.unread).map((n) => n.id),
      ['1', '3'],
    );
    expect(
      presenter.filter(notifications, InboxFilter.messages).map((n) => n.id),
      ['1', '2'],
    );
    expect(
      presenter.filter(notifications, InboxFilter.rides).map((n) => n.id),
      ['3'],
    );
  });

  test(
    'groups notifications chronologically into Today, Yesterday, Earlier',
    () {
      final presenter = InboxPresenter(referenceTime);
      final notifications = [
        buildNotification(
          id: 'today',
          timestamp: DateTime(2026, 11, 22, 14, 5),
        ),
        buildNotification(
          id: 'yesterday',
          timestamp: DateTime(2026, 11, 21, 9, 15),
        ),
        buildNotification(
          id: 'earlier',
          timestamp: DateTime(2026, 11, 18, 18, 45),
        ),
      ];

      final grouped = presenter.groupByDate(notifications);

      expect(grouped.keys.toList(), ['Today', 'Yesterday', 'Earlier']);
      expect(grouped['Today']!.single.id, 'today');
      expect(grouped['Yesterday']!.single.id, 'yesterday');
      expect(grouped['Earlier']!.single.id, 'earlier');
    },
  );

  test('formats timestamps for 12-hour, 24-hour, and prior years', () {
    final twelveHour = InboxPresenter(referenceTime);
    final twentyFourHour = InboxPresenter(
      referenceTime,
      alwaysUse24HourFormat: true,
    );

    expect(
      twelveHour.formatTimestamp(DateTime(2026, 11, 22, 14, 5)),
      '2:05 PM',
    );
    expect(
      twentyFourHour.formatTimestamp(DateTime(2026, 11, 22, 14, 5)),
      '14:05',
    );
    expect(
      twelveHour.formatTimestamp(DateTime(2026, 11, 21, 8, 0)),
      'Yesterday',
    );
    expect(twelveHour.formatTimestamp(DateTime(2026, 11, 18, 8, 0)), 'Nov 18');
    expect(
      twelveHour.formatTimestamp(DateTime(2025, 12, 31, 23, 59)),
      'Dec 31, 2025',
    );
    expect(
      twelveHour.formatFullTimestamp(DateTime(2026, 11, 21, 8, 5)),
      'Yesterday · 8:05 AM',
    );
    expect(
      twentyFourHour.formatFullTimestamp(DateTime(2025, 12, 31, 23, 59)),
      'Dec 31, 2025 · 23:59',
    );
  });
}
