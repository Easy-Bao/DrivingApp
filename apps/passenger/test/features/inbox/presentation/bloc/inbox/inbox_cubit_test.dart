import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/features/inbox/domain/entities/inbox_notification.dart';
import 'package:passenger/src/features/inbox/domain/repositories/inbox_repository.dart';
import 'package:passenger/src/features/inbox/presentation/bloc/inbox/inbox_cubit.dart';
import 'package:passenger/src/features/inbox/presentation/bloc/inbox/inbox_state.dart';

class MockInboxRepository extends Mock implements InboxRepository {}

class MockPaginatedInboxRepository extends Mock
    implements InboxRepository, PaginatedInboxRepository {}

void main() {
  final notification = InboxNotification(
    id: 'private-notification',
    title: 'Driver assigned',
    message: 'Private ride details',
    timestamp: DateTime(2026, 8, 7),
    type: 'ride',
    isRead: false,
  );

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
      final response = Completer<Either<Failure, List<InboxNotification>>>();
      when(() => repository.fetchPassengerNotifications('passenger-1'))
          .thenAnswer((_) => response.future);
      final cubit = InboxCubit(inboxRepository: repository);

      final pendingLoad = cubit.loadNotifications('passenger-1');
      expect(cubit.state, const InboxLoadingState());

      cubit.clearSessionData();
      response.complete(Right([notification]));
      await pendingLoad;

      expect(cubit.state, const InboxInitialState());
      await cubit.close();
    },
  );

  test('appends a paginated notification page', () async {
    final repository = MockPaginatedInboxRepository();
    when(
      () => repository.fetchPassengerNotificationsPage(
        'passenger-1',
        limit: 50,
        offset: 0,
      ),
    ).thenAnswer(
      (_) async => Right(
        OffsetPage(items: [notification], hasMore: true, nextOffset: 50),
      ),
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
          Right(OffsetPage(items: [older], hasMore: false, nextOffset: null)),
    );
    final cubit = InboxCubit(inboxRepository: repository);

    await cubit.loadNotifications('passenger-1');
    await cubit.loadMoreNotifications();

    final state = cubit.state as InboxLoadedState;
    expect(state.notifications, hasLength(1), reason: 'duplicate ids merge');
    expect(state.hasMore, isFalse);
    await cubit.close();
  });
}
