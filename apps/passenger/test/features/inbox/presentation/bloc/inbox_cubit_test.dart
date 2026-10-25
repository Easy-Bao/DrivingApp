import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/features/inbox/domain/entities/inbox_notification.dart';
import 'package:passenger/src/features/inbox/domain/repositories/inbox_repository.dart';
import 'package:passenger/src/features/inbox/presentation/bloc/inbox_cubit.dart';
import 'package:passenger/src/features/inbox/presentation/bloc/inbox_state.dart';

class MockInboxRepository extends Mock implements InboxRepository {}

class MockPaginatedInboxRepository extends Mock
    implements InboxRepository, PaginatedInboxRepository {}

class MockDismissibleInboxRepository extends Mock
    implements
        InboxRepository,
        PaginatedInboxRepository,
        DismissibleInboxRepository {}

void main() {
  final notification = InboxNotification(
    id: 'private-notification',
    title: 'Driver assigned',
    message: 'Private ride details',
    timestamp: DateTime(2026, 8, 7),
    type: 'ride',
    isRead: false,
  );

  test(
    'bulk read preserves arrivals and prevents duplicate requests',
    () async {
      final repository = MockInboxRepository();
      final response = Completer<Result<void, Failure>>();
      when(() => repository.fetchPassengerNotifications('p'))
          .thenAnswer((_) async => Ok([notification]));
      when(() => repository.markAllPassengerNotificationsAsRead('p'))
          .thenAnswer((_) => response.future);
      final cubit = InboxCubit(inboxRepository: repository);
      addTearDown(cubit.close);
      await cubit.loadNotifications('p');
      final pending = cubit.markAllNotificationsAsRead();
      expect((cubit.state as InboxLoadedState).isMarkingAllRead, isTrue);
      await cubit.markAllNotificationsAsRead();
      cubit.addLocalNotification(notification.copyWith(id: 'new'));
      response.complete(const Ok(null));
      await pending;
      final state = cubit.state as InboxLoadedState;
      expect(state.isMarkingAllRead, isFalse);
      expect(
        state.notifications.singleWhere((n) => n.id == notification.id).isRead,
        isTrue,
      );
      expect(
        state.notifications.singleWhere((n) => n.id == 'new').isRead,
        isFalse,
      );
      verify(() => repository.markAllPassengerNotificationsAsRead('p'))
          .called(1);
      await cubit.loadNotifications('p');
      expect(
        (cubit.state as InboxLoadedState).notifications
            .singleWhere((n) => n.id == notification.id)
            .isRead,
        isTrue,
      );
    },
  );

  test('bulk read failure keeps unread items and permits retry', () async {
    final repository = MockInboxRepository();
    when(() => repository.fetchPassengerNotifications('p'))
        .thenAnswer((_) async => Ok([notification]));
    when(() => repository.markAllPassengerNotificationsAsRead('p'))
        .thenAnswer((_) async => const Err(NetworkFailure('Offline')));
    final cubit = InboxCubit(inboxRepository: repository);
    addTearDown(cubit.close);
    await cubit.loadNotifications('p');
    await cubit.markAllNotificationsAsRead();
    final failed = cubit.state as InboxLoadedState;
    expect(failed.notifications.single.isRead, isFalse);
    expect(failed.markAllReadError, isNotNull);
    expect(failed.isMarkingAllRead, isFalse);
    when(() => repository.markAllPassengerNotificationsAsRead('p'))
        .thenAnswer((_) async => const Ok(null));
    await cubit.markAllNotificationsAsRead();
    expect(
      (cubit.state as InboxLoadedState).notifications.single.isRead,
      isTrue,
    );
    expect((cubit.state as InboxLoadedState).markAllReadError, isNull);
  });

  test('bulk read result cannot cross an account change', () async {
    final repository = MockInboxRepository();
    final response = Completer<Result<void, Failure>>();
    when(() => repository.fetchPassengerNotifications(any()))
        .thenAnswer((_) async => Ok([notification]));
    when(() => repository.markAllPassengerNotificationsAsRead('first'))
        .thenAnswer((_) => response.future);
    final cubit = InboxCubit(inboxRepository: repository);
    addTearDown(cubit.close);
    await cubit.loadNotifications('first');
    final pending = cubit.markAllNotificationsAsRead();
    cubit.clearSessionData();
    await cubit.loadNotifications('second');
    response.complete(const Ok(null));
    await pending;
    expect(
      (cubit.state as InboxLoadedState).notifications.single.isRead,
      isFalse,
    );
    expect((cubit.state as InboxLoadedState).isMarkingAllRead, isFalse);
  });

  test('clears passenger-scoped notifications when the session ends', () async {
    final cubit = InboxCubit(inboxRepository: MockInboxRepository());
    cubit.addLocalNotification(notification);

    expect(cubit.state, isA<InboxLoadedState>());

    cubit.clearSessionData();

    expect(cubit.state, const InboxInitialState());
    await cubit.close();
  });

  test(
    'discards a notification response that completes after logout',
    () async {
      final repository = MockInboxRepository();
      final response = Completer<Result<List<InboxNotification>, Failure>>();
      when(() => repository.fetchPassengerNotifications('passenger-1'))
          .thenAnswer((_) => response.future);
      final cubit = InboxCubit(inboxRepository: repository);

      final pendingLoad = cubit.loadNotifications('passenger-1');
      expect(cubit.state, const InboxLoadingState());

      cubit.clearSessionData();
      response.complete(Ok([notification]));
      await pendingLoad;

      expect(cubit.state, const InboxInitialState());
      await cubit.close();
    },
  );

  test('coalesces concurrent loads for the same passenger', () async {
    final repository = MockInboxRepository();
    final response = Completer<Result<List<InboxNotification>, Failure>>();
    when(() => repository.fetchPassengerNotifications('passenger-1'))
        .thenAnswer((_) => response.future);
    final cubit = InboxCubit(inboxRepository: repository);

    final firstLoad = cubit.loadNotifications('passenger-1');
    final secondLoad = cubit.loadNotifications('passenger-1');
    response.complete(Ok([notification]));
    await Future.wait([firstLoad, secondLoad]);

    verify(() => repository.fetchPassengerNotifications('passenger-1'))
        .called(1);
    await cubit.close();
  });

  test('appends a paginated notification page', () async {
    final repository = MockPaginatedInboxRepository();
    when(
      () => repository.fetchPassengerNotificationsPage(
        'passenger-1',
        limit: 50,
        offset: 0,
      ),
    ).thenAnswer(
      (_) async =>
          Ok(OffsetPage(items: [notification], hasMore: true, nextOffset: 50)),
    );
    final older = notification.copyWith(isRead: true);
    when(
      () => repository.fetchPassengerNotificationsPage(
        'passenger-1',
        limit: 50,
        offset: 50,
      ),
    ).thenAnswer(
      (_) async =>
          Ok(OffsetPage(items: [older], hasMore: false, nextOffset: null)),
    );
    final cubit = InboxCubit(inboxRepository: repository);

    await cubit.loadNotifications('passenger-1');
    await cubit.loadMoreNotifications();

    final state = cubit.state as InboxLoadedState;
    expect(state.notifications, hasLength(1), reason: 'duplicate ids merge');
    expect(state.hasMore, isFalse);
    await cubit.close();
  });

  test(
    'retains a notification after its legacy expiry timestamp passes',
    () async {
      final repository = MockInboxRepository();
      final legacyNotification = InboxNotification.fromJson(const {
        'id': 'legacy-notification',
        'title': 'Ride update',
        'body': 'Your ride is still available in history.',
        'type': 'ride',
        'is_read': true,
        'created_at': '2026-01-01T00:00:00Z',
        'expires_at': '2026-01-02T00:00:00Z',
      });
      when(() => repository.fetchPassengerNotifications('passenger-1'))
          .thenAnswer((_) async => Ok([legacyNotification]));
      final cubit = InboxCubit(inboxRepository: repository);

      await cubit.loadNotifications('passenger-1');

      final state = cubit.state as InboxLoadedState;
      expect(state.notifications.single, legacyNotification);
      await cubit.close();
    },
  );

  test('persists a server notification dismissal after a swipe', () async {
    final repository = MockDismissibleInboxRepository();
    final remoteNotification = notification.copyWith(id: '7');
    when(
      () => repository.fetchPassengerNotificationsPage(
        'passenger-1',
        limit: 50,
        offset: 0,
      ),
    ).thenAnswer(
      (_) async => Ok(
        OffsetPage(
          items: [remoteNotification],
          hasMore: false,
          nextOffset: null,
        ),
      ),
    );
    when(() => repository.deletePassengerNotification('passenger-1', '7'))
        .thenAnswer((_) async => const Ok(null));
    final cubit = InboxCubit(inboxRepository: repository);

    await cubit.loadNotifications('passenger-1');
    cubit.dismissNotification(0);
    await Future<void>.delayed(Duration.zero);

    expect((cubit.state as InboxLoadedState).notifications, isEmpty);
    verify(() => repository.deletePassengerNotification('passenger-1', '7'))
        .called(1);
    await cubit.close();
  });
}
